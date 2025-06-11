# --- AI-Prop-Protection PowerShell Release Publisher ---
# Version: 1.0
# Purpose: Commits, tags, and creates a new release on GitHub from the existing project build.
# IMPORTANT: This script should be run AFTER testing the build from Build-AIPP.ps1.

# --- Configuration ---
$ProjectParentPath = $PSScriptRoot
$ProjectName = "ai-prop-protection"
$ProjectPath = Join-Path $ProjectParentPath $ProjectName
$ReleaseZipPath = Join-Path $ProjectParentPath "_releases"

# --- Script Start ---
Clear-Host
Write-Host "====================================================" -ForegroundColor Green
Write-Host "     AI-Prop-Protection Release Publisher"
Write-Host "====================================================" -ForegroundColor Green
Write-Host ""

# --- Phase 1: Prerequisite & Project Check ---
if (-not (Test-Path $ProjectPath)) { Write-Host "[FATAL ERROR] Project folder '$ProjectName' not found. Please run the build script first." -ForegroundColor Red; return }
$gitExists = Get-Command git -ErrorAction SilentlyContinue
$ghExists = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gitExists) { Write-Host "[FATAL ERROR] Git not found." -ForegroundColor Red; return }
if (-not $ghExists) { Write-Host "[FATAL ERROR] GitHub CLI (gh) not found." -ForegroundColor Red; return }
if (-not (Test-Path (Join-Path $ProjectParentPath ".git"))) { Write-Host "[FATAL ERROR] This script must be run from inside a cloned Git repository." -ForegroundColor Red; return }

# --- Phase 2: Get Version and Release Notes ---
$Manifest = Get-Content (Join-Path $ProjectPath "manifest.json") -Raw | ConvertFrom-Json
$Version = $Manifest.version
Write-Host "Preparing to release version: v$Version" -ForegroundColor Cyan

$commitMessage = Read-Host "-> Enter a short commit message (e.g., 'Release v$Version')"
$releaseNotes = Read-Host "-> Enter release notes (a short description of what's new)"

# --- Phase 3: Create ZIP Archive for Release ---
if (-not (Test-Path $ReleaseZipPath)) { New-Item $ReleaseZipPath -ItemType Directory -Force | Out-Null }
$ZipFileName = "${ProjectName}_v${Version}.zip"
$ZipFullPath = Join-Path $ReleaseZipPath $ZipFileName
Write-Host "-> Creating ZIP archive for release..." -ForegroundColor Yellow
Compress-Archive -Path "$ProjectPath\*" -DestinationPath $ZipFullPath -Force
Write-Host "   Release archive created: _releases\$ZipFileName"

# --- Phase 4: Git and GitHub Commands ---
Write-Host "-> Committing and pushing to GitHub..."
git add .
git commit -m $commitMessage
git tag "v$Version"
git push origin master
git push --tags
Write-Host "   Code and tags pushed successfully."

Write-Host "-> Creating GitHub Release..."
gh release create "v$Version" "$ZipFullPath" --title $commitMessage --notes $releaseNotes --latest
Write-Host "   GitHub release created and ZIP uploaded."

# --- Final Instructions ---
Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "     RELEASE COMPLETE"
Write-Host "====================================================" -ForegroundColor Green
Write-Host ""
$repoUrl = git remote get-url origin
if ($repoUrl -and $repoUrl.StartsWith("https:")) {
    $releaseUrl = $repoUrl.Replace(".git", "/releases/tag/v$Version")
    Write-Host "You can view the new release at: $releaseUrl" -ForegroundColor Yellow
}