<#
.SYNOPSIS
    Starts a local development HTTP server for the Student Portal website.
.DESCRIPTION
    Uses native .NET HttpListener built into Windows PowerShell (no external dependencies required).
    Serves the /frontend directory on http://localhost:8080 and automatically opens your browser.
#>

$port = 8080

# Check if website files are in the root directory or frontend/ subdirectory
if (Test-Path (Join-Path $PSScriptRoot "index.html")) {
    $folder = $PSScriptRoot
} elseif (Test-Path (Join-Path $PSScriptRoot "frontend\index.html")) {
    $folder = Join-Path $PSScriptRoot "frontend"
} else {
    Write-Error "Could not locate index.html in $PSScriptRoot"
    exit 1
}

$url = "http://localhost:$port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)

try {
    $listener.Start()
} catch {
    Write-Warning "Port $port might be in use or requires elevation. Launching default browser directly with HTML file..."
    Start-Process (Join-Path $folder "index.html")
    exit 0
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " 🎓 AWS Student Portal - Local Development Web Server" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Server Running at : $url" -ForegroundColor Yellow
Write-Host " Document Root     : $folder" -ForegroundColor Yellow
Write-Host " Health Endpoint   : ${url}health.html" -ForegroundColor Yellow
Write-Host " Press [Ctrl + C] in this window to stop the server." -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Cyan

# Open default browser automatically
Start-Process $url

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    $requestPath = $request.Url.LocalPath.TrimStart('/')
    if ([string]::IsNullOrEmpty($requestPath) -or $requestPath -eq "/") {
        $requestPath = "index.html"
    } elseif ($requestPath -eq "health") {
        # Handle clean /health route like Apache does
        $requestPath = "health.html"
    }

    $filePath = Join-Path $folder $requestPath

    if (Test-Path $filePath -PathType Leaf) {
        $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
        $contentType = switch ($ext) {
            ".html" { "text/html; charset=utf-8" }
            ".css"  { "text/css; charset=utf-8" }
            ".js"   { "application/javascript; charset=utf-8" }
            ".json" { "application/json; charset=utf-8" }
            ".png"  { "image/png" }
            ".jpg"  { "image/jpeg" }
            ".svg"  { "image/svg+xml" }
            default { "application/octet-stream" }
        }

        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $response.ContentType = $contentType
        $response.ContentLength64 = $bytes.Length
        $response.StatusCode = 200
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
        Write-Host " [200 OK] $($request.HttpMethod) /$requestPath" -ForegroundColor DarkGreen
    } else {
        $response.StatusCode = 404
        $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $requestPath")
        $response.ContentType = "text/plain"
        $response.ContentLength64 = $msg.Length
        $response.OutputStream.Write($msg, 0, $msg.Length)
        Write-Host " [404 Not Found] $($request.HttpMethod) /$requestPath" -ForegroundColor Red
    }
    $response.OutputStream.Close()
}
