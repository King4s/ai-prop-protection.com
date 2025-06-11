# --- AI-Prop-Protection PowerShell Release Publisher ---
# Version: 2.0 (Intelligent Version Suggestion)
# Purpose: Commits, tags, and creates a new release on GitHub.
# - Intelligently finds the latest GitHub release and suggests the next version number.

# --- Configuration ---
$ProjectParentPath = $PSScriptRoot
$ProjectName = "ai-prop-protection"
$ProjectPath = Join-Path $ProjectParentPath $ProjectName
$ReleaseZipPath = Join-Path $ProjectParentPath "_releases"
$InitialVersion = "1.0.0"

# --- Script Start ---
Clear-Host
Write-Host "====================================================" -ForegroundColor Green
Write-Host "     AI-Prop-Protection Release Publisher"
Write-Host "====================================================" -ForegroundColor Green
Write-Host ""

# --- Phase 1: Prerequisite & Project Check ---
if (-not (Test-Path $ProjectPath)) { Write-Host "[FATAL ERROR] Project folder '$ProjectName' not found. Please run the build script first." -ForegroundColor Red; return }
$gitExists = Get-Command git -ErrorAction SilentlyContinue; if (-not $gitExists) { Write-Host "[FATAL ERROR] Git not found." -ForegroundColor Red; return }
$ghExists = Get-Command gh -ErrorAction SilentlyContinue; if (-not $ghExists) { Write-Host "[FATAL ERROR] GitHub CLI (gh) not found." -ForegroundColor Red; return }
if (-not (Test-Path (Join-Path $ProjectParentPath ".git"))) { Write-Host "[FATAL ERROR] This script must be run from inside a cloned Git repository." -ForegroundColor Red; return }

# --- Phase 2: Intelligent Version Detection ---
Write-Host "-> Fetching latest release from GitHub..." -ForegroundColor Cyan
$latestReleaseOutput = gh release list --limit 1
$suggestedVersion = $InitialVersion

if ($latestReleaseOutput) {
    # Extract the tag name, which is the 3rd column, separated by tabs
    $latestTag = ($latestReleaseOutput.Split("`t"))[2]
    Write-Host "   Latest release found on GitHub: $latestTag"
    
    $versionString = $latestTag.TrimStart('v')
    $versionParts = $versionString.Split('.')
    
    if ($versionParts.Count -ge 3) {
        $newPatchNumber = ([int]$versionParts[-1]) + 1
        $versionParts[-1] = $newPatchNumber.ToString()
        $suggestedVersion = $versionParts -join '.'
    }
    Write-Host "   Suggested next version: $suggestedVersion" -ForegroundColor Yellow
} else {
    Write-Host "   No previous releases found. Starting with initial version: $InitialVersion" -ForegroundColor Yellow
}

Write-Host ""
$Version = Read-Host "-> Enter the version number for this release (Press Enter to use '$suggestedVersion')"
if (-not $Version) { $Version = $suggestedVersion }

# --- Phase 3: Update Manifest and Get Notes ---
Write-Host "-> Updating manifest to version $Version..."
$manifestPath = Join-Path $ProjectPath "manifest.json"
$Manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$Manifest.version = $Version
$Manifest | ConvertTo-Json -Depth 5 | Set-Content $manifestPath -Encoding UTF8
Write-Host "   manifest.json updated."

$commitMessage = Read-Host "-> Enter a short commit message (Press Enter for 'Release v$Version')"
if (-not $commitMessage) { $commitMessage = "Release v${Version}" }
$releaseNotes = Read-Host "-> Enter release notes (a short description of what's new)"
if (-not $releaseNotes) { $releaseNotes = "No release notes provided." }

# --- Phase 4: Create ZIP Archive for Release ---
if (-not (Test-Path $ReleaseZipPath)) { New-Item $ReleaseZipPath -ItemType Directory -Force | Out-Null }
$ZipFileName = "${ProjectName}_v${Version}.zip"
$ZipFullPath = Join-Path $ReleaseZipPath $ZipFileName
Write-Host "-> Creating ZIP archive for release..." -ForegroundColor Yellow
Compress-Archive -Path "$ProjectPath\*" -DestinationPath $ZipFullPath -Force
Write-Host "   Release archive created: _releases\$ZipFileName"

# --- Phase 5: Git and GitHub Commands ---
$defaultBranch = git symbolic-ref refs/remotes/origin/HEAD | ForEach-Object { $_.Split('/')[-1] }
if (-not $defaultBranch) { $defaultBranch = "main" }
Write-Host "-> Committing and pushing to default branch: '$defaultBranch'"
git add .
git commit -m $commitMessage
git tag "v$Version"
git push origin $defaultBranch
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
if ($repoUrl -and $repoUrl.StartsWith("https")) {
    $releaseUrl = $repoUrl.Replace(".git", "/releases/tag/v$Version")
    Write-Host "You can view the new release at: $releaseUrl" -ForegroundColor Yellow
}