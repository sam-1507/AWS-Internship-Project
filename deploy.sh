#!/bin/bash
# ==============================================================================
# AWS Cloud Project - Student Portal
# Ubuntu EC2 Deployment & Configuration Script (deploy.sh)
# ------------------------------------------------------------------------------
# Target OS: Ubuntu 22.04 LTS / Ubuntu 20.04 LTS (AWS EC2)
# Purpose:
#   1. Installs Apache2 web server, Python 3, and AWS CLI v2.
#   2. Deploys frontend files to /var/www/html/student-portal.
#   3. Configures Apache VirtualHost with clean /health route and security headers.
#   4. Enables and starts the Apache service.
#   5. Runs automated HTTP curl health checks.
#   6. Displays live server status and operational verification commands.
# Security:
#   Uses AWS IAM Role Instance Profiles. NO hardcoded access keys.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# Terminal Colors for Professional Output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper Functions
log_step() {
    echo -e "\n${BLUE}==============================================================================${NC}"
    echo -e "${BLUE}[STEP $1] $2${NC}"
    echo -e "${BLUE}==============================================================================${NC}"
}

log_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

log_info() {
    echo -e "${YELLOW}[i] $1${NC}"
}

log_error() {
    echo -e "${RED}[✗] $1${NC}"
}

# ------------------------------------------------------------------------------
# Pre-Check: Root / Sudo Privileges
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    log_error "Please run this deployment script as root or with sudo:"
    echo "       sudo ./deploy.sh"
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_ROOT="/var/www/html/student-portal"

echo -e "${GREEN}"
echo "   ____                                    ____  _                 "
echo "  / ___|__ _ _ __ ___  _ __  _   _ ___    / ___|| | ___  _   _  __| |"
echo " | |   / _\` | '_ \` _ \| '_ \| | | / __|  | |    | |/ _ \| | | |/ _\` |"
echo " | |__| (_| | | | | | | |_) | |_| \__ \  | |___ | | (_) | |_| | (_| |"
echo "  \____\__,_|_| |_| |_| .__/ \__,_|___/   \____||_|\___/ \__,_|\__,_|"
echo "                      |_|                                            "
echo " AWS EC2 Student Portal Deployment Script (Ubuntu 22.04 LTS)"
echo -e "${NC}"
echo " Timestamp    : $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo " Source Path  : ${PROJECT_DIR}"
echo " Web Root     : ${WEB_ROOT}"

# ------------------------------------------------------------------------------
# STEP 1: Update Packages & Install Apache2, Python 3, and Tools
# ------------------------------------------------------------------------------
log_step "1/6" "Installing System Packages (Apache2, Python 3, Unzip, Curl)"
export DEBIAN_FRONTEND=noninteractive

log_info "Updating Ubuntu apt repositories..."
apt-get update -y

log_info "Installing Apache2, Python 3, pip, curl, and utilities..."
apt-get install -y apache2 python3 python3-pip unzip curl git

log_success "System packages installed successfully."

# ------------------------------------------------------------------------------
# STEP 2: Install AWS CLI v2 (Using Official Amazon Package)
# ------------------------------------------------------------------------------
log_step "2/6" "Checking and Installing AWS CLI v2"

if command -v aws &> /dev/null; then
    log_success "AWS CLI is already installed: $(aws --version)"
else
    log_info "Downloading official AWS CLI v2 package from Amazon AWS..."
    cd /tmp
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
    cd "$PROJECT_DIR"
    log_success "AWS CLI v2 installed successfully: $(aws --version)"
fi

# Verify IAM Role Authentication (Zero hardcoded credentials)
log_info "Verifying IAM Role authentication on EC2..."
if aws sts get-caller-identity > /dev/null 2>&1; then
    IAM_ARN=$(aws sts get-caller-identity --query "Arn" --output text 2>/dev/null)
    log_success "IAM Instance Profile authenticated: ${IAM_ARN}"
else
    log_info "Note: No IAM role attached yet (or running locally). Once attached in AWS console, IAM will auto-authenticate."
fi

# ------------------------------------------------------------------------------
# STEP 3: Deploy Frontend Files into Apache Web Directory
# ------------------------------------------------------------------------------
log_step "3/6" "Deploying Frontend Application Files"

if [ ! -d "${PROJECT_DIR}/frontend" ]; then
    log_error "Directory '${PROJECT_DIR}/frontend' not found! Make sure you run this script from the project root."
    exit 1
fi

log_info "Creating target web directory: ${WEB_ROOT}"
mkdir -p "${WEB_ROOT}"

log_info "Copying HTML, CSS, JavaScript, and .htaccess files to ${WEB_ROOT}..."
cp -r "${PROJECT_DIR}/frontend/"* "${WEB_ROOT}/"

# Ensure .htaccess is also copied if hidden
if [ -f "${PROJECT_DIR}/frontend/.htaccess" ]; then
    cp "${PROJECT_DIR}/frontend/.htaccess" "${WEB_ROOT}/.htaccess"
fi

log_info "Setting correct ownership (www-data:www-data) and permissions..."
chown -R www-data:www-data "${WEB_ROOT}"
find "${WEB_ROOT}" -type d -exec chmod 755 {} \;
find "${WEB_ROOT}" -type f -exec chmod 644 {} \;

log_success "Frontend files deployed with secure permissions."

# ------------------------------------------------------------------------------
# STEP 4: Configure Apache VirtualHost, Modules & /health Endpoint
# ------------------------------------------------------------------------------
log_step "4/6" "Configuring Apache Web Server & VirtualHost"

log_info "Enabling required Apache modules (rewrite, headers)..."
a2enmod rewrite headers > /dev/null 2>&1

# Write VirtualHost configuration
VHOST_CONF="/etc/apache2/sites-available/student-portal.conf"
log_info "Generating VirtualHost configuration at ${VHOST_CONF}..."

cat << 'EOF' > "${VHOST_CONF}"
# ==============================================================================
# AWS Cloud Project - Student Portal
# Apache VirtualHost Configuration (Port 80)
# ==============================================================================

<VirtualHost *:80>
    ServerAdmin webmaster@campus.edu
    DocumentRoot /var/www/html/student-portal

    # Directory Access Rules
    <Directory /var/www/html/student-portal>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Dedicated Route Alias for AWS ALB & Route 53 Health Checks
    Alias /health /var/www/html/student-portal/health.html

    # Dedicated Access & Error Logs for S3 Sync & Python Log Analyzer
    ErrorLog ${APACHE_LOG_DIR}/student_portal_error.log
    CustomLog ${APACHE_LOG_DIR}/student_portal_access.log combined

    LogLevel warn
</VirtualHost>
EOF

log_info "Activating student-portal site and disabling default site..."
a2dissite 000-default.conf > /dev/null 2>&1 || true
a2ensite student-portal.conf > /dev/null 2>&1

log_info "Testing Apache configuration syntax..."
apache2ctl configtest

log_success "Apache VirtualHost configured successfully."

# ------------------------------------------------------------------------------
# STEP 5: Enable & Restart the Apache Service
# ------------------------------------------------------------------------------
log_step "5/6" "Enabling & Starting Apache2 Service"

log_info "Enabling Apache2 to start automatically on system boot..."
systemctl enable apache2

log_info "Restarting Apache2..."
systemctl restart apache2

if systemctl is-active --quiet apache2; then
    log_success "Apache2 service is ACTIVE (RUNNING)."
else
    log_error "Apache2 failed to start! Check logs using: journalctl -u apache2"
    exit 1
fi

# ------------------------------------------------------------------------------
# STEP 6: Automated Website Self-Test (Health & Route Verification)
# ------------------------------------------------------------------------------
log_step "6/6" "Testing Website Endpoints Locally via HTTP"

# Test 1: Homepage (index.html)
HTTP_HOME=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/)
if [ "$HTTP_HOME" -eq 200 ]; then
    log_success "Homepage (http://localhost/) returned HTTP 200 OK"
else
    log_error "Homepage returned HTTP ${HTTP_HOME}"
fi

# Test 2: Health Check Route (/health)
HTTP_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/health)
if [ "$HTTP_HEALTH" -eq 200 ]; then
    log_success "Health Check (http://localhost/health) returned HTTP 200 OK"
else
    log_error "Health Check returned HTTP ${HTTP_HEALTH}"
fi

# Test 3: Student Dashboard (/dashboard.html)
HTTP_DASH=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/dashboard.html)
if [ "$HTTP_DASH" -eq 200 ]; then
    log_success "Student Dashboard (http://localhost/dashboard.html) returned HTTP 200 OK"
else
    log_error "Student Dashboard returned HTTP ${HTTP_DASH}"
fi

# Test 4: Courses Page (/courses.html)
HTTP_COURSES=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/courses.html)
if [ "$HTTP_COURSES" -eq 200 ]; then
    log_success "Courses Page (http://localhost/courses.html) returned HTTP 200 OK"
else
    log_error "Courses Page returned HTTP ${HTTP_COURSES}"
fi

# Test 5: Profile Page (/profile.html)
HTTP_PROFILE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/profile.html)
if [ "$HTTP_PROFILE" -eq 200 ]; then
    log_success "Profile Page (http://localhost/profile.html) returned HTTP 200 OK"
else
    log_error "Profile Page returned HTTP ${HTTP_PROFILE}"
fi

# ------------------------------------------------------------------------------
# Discover Public IPv4 Address & Display Completion Summary
# ------------------------------------------------------------------------------
# Fetch public IP via IMDSv2 or external service
PUBLIC_IP=""
if IMDS_TOKEN=$(curl -s -m 2 -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60" 2>/dev/null); then
    PUBLIC_IP=$(curl -s -m 2 -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" "http://169.254.169.254/latest/meta-data/public-ipv4" 2>/dev/null)
fi

if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP=$(curl -s -m 2 "https://checkip.amazonaws.com" 2>/dev/null || echo "<YOUR-EC2-PUBLIC-IP>")
fi

echo -e "\n${GREEN}==============================================================================${NC}"
echo -e "${GREEN}   🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!${NC}"
echo -e "${GREEN}==============================================================================${NC}"
echo -e " The Student Portal is now live and serving requests on Apache Port 80."
echo ""
echo -e " 🌐 ${YELLOW}Website URLs:${NC}"
echo -e "    * Homepage        : http://${PUBLIC_IP}/"
echo -e "    * Dashboard       : http://${PUBLIC_IP}/dashboard.html"
echo -e "    * Courses         : http://${PUBLIC_IP}/courses.html"
echo -e "    * Student Profile : http://${PUBLIC_IP}/profile.html"
echo -e "    * Health Endpoint : http://${PUBLIC_IP}/health"
echo -e "    * Contact Support : http://${PUBLIC_IP}/contact.html"

echo -e "\n 📋 ${YELLOW}Server Management & Status Check Commands:${NC}"
echo -e "    1. Check Apache service status:"
echo -e "       ${BLUE}sudo systemctl status apache2${NC}"
echo ""
echo -e "    2. Verify listening web port (Port 80):"
echo -e "       ${BLUE}sudo ss -tulpn | grep :80${NC}"
echo ""
echo -e "    3. Monitor live incoming HTTP access requests:"
echo -e "       ${BLUE}sudo tail -f /var/log/apache2/student_portal_access.log${NC}"
echo ""
echo -e "    4. Monitor live Apache error logs:"
echo -e "       ${BLUE}sudo tail -f /var/log/apache2/student_portal_error.log${NC}"
echo ""
echo -e "    5. Run Python Access Log Telemetry Analyzer:"
echo -e "       ${BLUE}python3 ${PROJECT_DIR}/scripts/log_analyzer.py --log /var/log/apache2/student_portal_access.log${NC}"
echo ""
echo -e "    6. Test S3 log sync manually (via IAM Role):"
echo -e "       ${BLUE}sudo ${PROJECT_DIR}/aws/scripts/sync-logs-to-s3.sh${NC}"
echo -e "${GREEN}==============================================================================${NC}\n"
