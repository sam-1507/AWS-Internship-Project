/**
 * ==============================================================================
 * AWS Student Portal with Cloud Monitoring
 * File: script.js
 * Purpose: Interactive UI logic, student sample data, live search & notifications.
 * Beginner-friendly, vanilla JavaScript without external libraries.
 * ==============================================================================
 */

// --- 1. Central Sample Student Data Object ---
const studentData = {
    // Student Personal & Academic Profile
    profile: {
        id: "STU-2026-8842",
        fullName: "Alex Rivera",
        email: "alex.rivera@campus.edu",
        degree: "Bachelor of Technology (B.Tech)",
        major: "Computer Science & Cloud Systems",
        semester: "Semester 6 (Final Year)",
        academicStanding: "Good Standing (Dean's List)",
        advisor: "Dr. Sarah Mitchell",
        gpa: "3.84",
        attendanceRate: "92.5%",
        tuitionStatus: "Paid in Full",
        totalCredits: "104 / 120"
    },

    // Enrolled Academic Courses
    courses: [
        {
            code: "CS-401",
            title: "Cloud Architecture & AWS Infrastructure",
            instructor: "Prof. Alan Vance",
            credits: 4,
            attendance: "96%",
            grade: "A",
            progress: 85
        },
        {
            code: "CS-405",
            title: "Distributed Systems & Scalability",
            instructor: "Dr. Elena Rostova",
            credits: 3,
            attendance: "91%",
            grade: "A-",
            progress: 70
        },
        {
            code: "CS-412",
            title: "Information Security & IAM Governance",
            instructor: "Prof. Kenneth Clark",
            credits: 3,
            attendance: "88%",
            grade: "B+",
            progress: 90
        },
        {
            code: "CS-420",
            title: "Full Stack Web Development",
            instructor: "Dr. Rachel Green",
            credits: 4,
            attendance: "94%",
            grade: "A",
            progress: 95
        },
        {
            code: "CS-499",
            title: "Senior Capstone Cloud Project",
            instructor: "Dept. Committee",
            credits: 2,
            attendance: "100%",
            grade: "A+",
            progress: 80
        }
    ],

    // Chronological Activity Feed
    activities: [
        {
            title: "Cloud Capstone Milestone 3 Submitted",
            desc: "Submitted custom VPC architecture diagram & Apache bootstrap script.",
            time: "2 hours ago"
        },
        {
            title: "Spring Term Tuition Fee Verified",
            desc: "Payment receipt #RCPT-8842 verified and archived to S3 storage.",
            time: "Yesterday, 04:15 PM"
        },
        {
            title: "Mid-Term Grade Published: CS-401",
            desc: "Prof. Alan Vance published midterm exam grades (Scored 94/100).",
            time: "2 days ago"
        },
        {
            title: "AWS Architecture Guide Loan Extended",
            desc: "North Campus Library loan renewed until final exams.",
            time: "4 days ago"
        },
        {
            title: "Student Portal Login via EC2",
            desc: "Authenticated session started from campus network.",
            time: "1 week ago"
        }
    ]
};

// --- 2. Initialize Application on DOM Ready ---
document.addEventListener("DOMContentLoaded", () => {
    // Setup Mobile Navigation Menu
    setupMobileNav();

    // Auto-highlight active navigation link
    highlightActiveNavLink();

    // Set current year in footer
    setCurrentYear();

    // Bind Student Profile Data to HTML elements
    bindStudentProfile();

    // Render Course Table in Dashboard (if table exists)
    renderCourseTable(studentData.courses);

    // Setup Course Search Filter
    setupCourseSearch();

    // Render Recent Activities Timeline (if container exists)
    renderRecentActivities();

    // Setup Contact Form Submissions (if form exists)
    setupContactForm();

    // Setup Download Transcript simulated buttons
    setupDownloadButtons();

    // Update Health Check live timestamp (if health page)
    updateHealthTimestamp();

    console.log("CampusCloud Student Portal loaded successfully.");
});

// --- 3. Responsive Mobile Menu Function ---
function setupMobileNav() {
    const mobileToggle = document.getElementById("mobileToggle");
    const navLinks = document.getElementById("navLinks");

    if (mobileToggle && navLinks) {
        mobileToggle.addEventListener("click", () => {
            navLinks.classList.toggle("show");
            const isOpen = navLinks.classList.contains("show");
            mobileToggle.setAttribute("aria-expanded", isOpen);
        });

        // Close menu when clicking outside
        document.addEventListener("click", (e) => {
            if (!navLinks.contains(e.target) && !mobileToggle.contains(e.target)) {
                navLinks.classList.remove("show");
                mobileToggle.setAttribute("aria-expanded", "false");
            }
        });
    }
}

// --- 4. Auto-Highlight Active Navigation Link ---
function highlightActiveNavLink() {
    const rawPath = window.location.pathname.split("/").pop() || "index.html";
    const currentFile = rawPath.endsWith(".html") ? rawPath : (rawPath === "" ? "index.html" : rawPath + ".html");

    const links = document.querySelectorAll(".nav-links a");
    links.forEach(link => {
        const href = link.getAttribute("href");
        if (href === currentFile || (currentFile === "index.html" && (href === "" || href === "index.html"))) {
            link.classList.add("active");
        } else {
            link.classList.remove("active");
        }
    });
}

// --- 5. Dynamic Footer Year ---
function setCurrentYear() {
    const yearEls = document.querySelectorAll(".current-year, #currentYear");
    const year = new Date().getFullYear();
    yearEls.forEach(el => {
        el.textContent = year;
    });
}

// --- 6. Bind Student Profile to HTML Elements ---
function bindStudentProfile() {
    const p = studentData.profile;
    const bindings = {
        studentName: p.fullName,
        studentId: p.id,
        studentEmail: p.email,
        studentDegree: p.degree,
        studentMajor: p.major,
        studentSemester: p.semester,
        studentAdvisor: p.advisor,
        studentGpa: p.gpa,
        studentAttendance: p.attendanceRate,
        studentFees: p.tuitionStatus,
        studentCredits: p.totalCredits,
        studentStatus: p.academicStanding
    };

    // Find and update all matching data-field, class, or id elements
    for (const [key, value] of Object.entries(bindings)) {
        const elements = document.querySelectorAll(`[data-field="${key}"], .${key}, #${key}`);
        elements.forEach(el => {
            el.textContent = value;
        });
    }
}

// --- 7. Render Enrolled Courses Table ---
function renderCourseTable(courses) {
    const tableBody = document.getElementById("coursesTableBody");
    if (!tableBody) return;

    if (courses.length === 0) {
        tableBody.innerHTML = `
            <tr>
                <td colspan="6" style="text-align: center; color: var(--text-muted); padding: 1.5rem;">
                    No enrolled courses matched your search query.
                </td>
            </tr>
        `;
        return;
    }

    tableBody.innerHTML = courses.map(course => `
        <tr>
            <td><span class="course-code">${course.code}</span></td>
            <td>
                <strong>${course.title}</strong><br>
                <small style="color: var(--text-muted);">${course.instructor}</small>
            </td>
            <td><strong>${course.credits}</strong></td>
            <td><span style="color: var(--success-green); font-weight: 600;">${course.attendance}</span></td>
            <td style="min-width: 140px;">
                <div style="display: flex; justify-content: space-between; font-size: 0.75rem; margin-bottom: 2px;">
                    <span>Syllabus</span>
                    <span><strong>${course.progress}%</strong></span>
                </div>
                <div class="progress-bar-bg">
                    <div class="progress-bar-fill" style="width: ${course.progress}%;"></div>
                </div>
            </td>
            <td>
                <span class="badge badge-blue">Grade: ${course.grade}</span>
            </td>
        </tr>
    `).join("");
}

// --- 8. Setup Live Course Search Filter ---
function setupCourseSearch() {
    const searchInput = document.getElementById("courseSearch");
    if (!searchInput) return;

    searchInput.addEventListener("input", (e) => {
        const query = e.target.value.toLowerCase().trim();
        const filtered = studentData.courses.filter(course =>
            course.title.toLowerCase().includes(query) ||
            course.code.toLowerCase().includes(query) ||
            course.instructor.toLowerCase().includes(query)
        );
        renderCourseTable(filtered);
    });
}

// --- 9. Render Recent Activities Timeline ---
function renderRecentActivities() {
    const container = document.getElementById("activityFeed");
    if (!container) return;

    container.innerHTML = studentData.activities.map(act => `
        <li class="activity-item">
            <span class="activity-dot"></span>
            <div class="activity-content">
                <span class="activity-time">${act.time}</span>
                <div class="activity-title">${act.title}</div>
                <p class="activity-desc">${act.desc}</p>
            </div>
        </li>
    `).join("");
}

// --- 10. Contact Form Submission Handler ---
function setupContactForm() {
    const contactForm = document.getElementById("contactForm");
    if (!contactForm) return;

    contactForm.addEventListener("submit", (e) => {
        e.preventDefault(); // Prevent page refresh

        const nameInput = document.getElementById("fullName");
        const studentName = nameInput ? nameInput.value : "Student";

        showToast(`Thank you, ${studentName}! Your ticket has been logged successfully.`, "success");
        contactForm.reset();
    });
}

// --- 11. Reusable Download / Simulated S3 Buttons ---
function setupDownloadButtons() {
    const downloadBtns = document.querySelectorAll(".btn-download");
    downloadBtns.forEach(btn => {
        btn.addEventListener("click", () => {
            showToast("Generating Academic Transcript PDF...", "info");
            setTimeout(() => {
                showToast("Download ready! (Simulated via AWS S3 storage)", "success");
            }, 1000);
        });
    });
}

// --- 12. Health Check Live ISO Timestamp ---
function updateHealthTimestamp() {
    const tsEl = document.getElementById("liveTimestamp");
    if (tsEl) {
        tsEl.textContent = new Date().toISOString();
    }
}

// --- 13. Reusable Toast Notification Utility ---
function showToast(message, type = "info") {
    let container = document.getElementById("toast-container");
    if (!container) {
        container = document.createElement("div");
        container.id = "toast-container";
        container.style.position = "fixed";
        container.style.bottom = "20px";
        container.style.right = "20px";
        container.style.zIndex = "9999";
        container.style.display = "flex";
        container.style.flexDirection = "column";
        container.style.gap = "10px";
        document.body.appendChild(container);
    }

    const toast = document.createElement("div");
    toast.style.padding = "12px 20px";
    toast.style.borderRadius = "8px";
    toast.style.color = "#ffffff";
    toast.style.fontSize = "0.9rem";
    toast.style.fontWeight = "600";
    toast.style.boxShadow = "0 4px 12px rgba(0,0,0,0.15)";
    toast.style.transition = "all 0.3s ease";
    toast.style.opacity = "0";
    toast.style.transform = "translateY(10px)";

    if (type === "success") {
        toast.style.backgroundColor = "#10b981"; // Emerald
    } else if (type === "warning") {
        toast.style.backgroundColor = "#f59e0b"; // Amber
    } else {
        toast.style.backgroundColor = "#2563eb"; // Tech Blue
    }

    toast.innerText = message;
    container.appendChild(toast);

    // Fade in
    setTimeout(() => {
        toast.style.opacity = "1";
        toast.style.transform = "translateY(0)";
    }, 10);

    // Fade out and remove
    setTimeout(() => {
        toast.style.opacity = "0";
        toast.style.transform = "translateY(10px)";
        setTimeout(() => toast.remove(), 300);
    }, 3500);
}
