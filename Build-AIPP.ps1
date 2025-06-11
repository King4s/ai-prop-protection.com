# --- AI-Prop-Protection PowerShell Project Builder ---
# Version: 6.1 (Syntax-Corrected Build & Release Pipeline)
# Purpose: A professional build-and-release pipeline script with corrected PowerShell syntax.

# --- Configuration ---
$ProjectParentPath = $PSScriptRoot
$ProjectName = "ai-prop-protection"
$ProjectPath = Join-Path $ProjectParentPath $ProjectName
$BackupDirPath = Join-Path $ProjectParentPath "_backups"
$IconsTempPath = Join-Path $ProjectParentPath "_temp_icons"
$InitialVersion = "1.0.0"

# --- Script Start ---
Clear-Host
Write-Host "====================================================" -ForegroundColor Green
Write-Host "     AI-Prop-Protection Build & Release Pipeline"
Write-Host "====================================================" -ForegroundColor Green
Write-Host "Workspace: $ProjectParentPath" -ForegroundColor Cyan
Write-Host ""

# --- Phase 1: Prerequisite Check ---
Write-Host "-> Checking for required tools..."
$gitExists = Get-Command git -ErrorAction SilentlyContinue
$ghExists = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gitExists) { Write-Host "[FATAL ERROR] Git is not installed. Please install from: https://git-scm.com/download/win" -ForegroundColor Red; return }
if (-not $ghExists) { Write-Host "[FATAL ERROR] GitHub CLI (gh) is not installed. Please install from: https://cli.github.com/ and run 'gh auth login'." -ForegroundColor Red; return }
Write-Host "   Git and GitHub CLI are installed."

# --- Phase 2: Git Repository Check ---
if (-not (Test-Path (Join-Path $ProjectParentPath ".git"))) {
    Write-Host "-> This directory is not a Git repository." -ForegroundColor Yellow
    $initRepo = Read-Host "Do you want to initialize it and connect to GitHub? [Y/N]"
    if ($initRepo -eq 'Y') {
        git init
        $repoUrl = Read-Host "Please enter your full GitHub repository URL (e.g., https://github.com/user/repo.git)"
        git remote add origin $repoUrl
        Write-Host "   Git repository initialized." -ForegroundColor Green
    } else { Write-Host "[ERROR] Cannot proceed without a Git repository. Exiting." -ForegroundColor Red; return }
}

# --- Phase 3: Build Process ---
$OldVersion = $InitialVersion
if (Test-Path $ProjectPath) {
    if (Test-Path (Join-Path $ProjectPath "manifest.json")) {
        try {
            $OldManifest = Get-Content -Path (Join-Path $ProjectPath "manifest.json") -Raw | ConvertFrom-Json
            $OldVersion = $OldManifest.version
            $VersionParts = $OldVersion.Split('.');
            while ($VersionParts.Count -lt 3) { $VersionParts += "0" }
            $NewPatchNumber = ([int]$VersionParts[-1]) + 1
            $VersionParts[-1] = $NewPatchNumber.ToString()
            $NewVersion = $VersionParts -join '.'
        } catch { $NewVersion = $InitialVersion }
    } else { $NewVersion = $InitialVersion }
    if (Test-Path (Join-Path $ProjectPath "icons")) { Move-Item -Path (Join-Path $ProjectPath "icons") -Destination $IconsTempPath -Force }
    if (-not (Test-Path $BackupDirPath)) { New-Item -Path $BackupDirPath -ItemType Directory -Force | Out-Null }
    $ZipFileName = "${ProjectName}_v${OldVersion}.zip"; $ZipFullPath = Join-Path $BackupDirPath $ZipFileName
    Write-Host "-> Creating ZIP backup of v$OldVersion..." -ForegroundColor Yellow
    Compress-Archive -Path "$ProjectPath\*" -DestinationPath $ZipFullPath -Force; Write-Host "   Backup created: _backups\$ZipFileName"
    Remove-Item -Path $ProjectPath -Recurse -Force
} else { $NewVersion = $InitialVersion }

Write-Host "-> Building structure for new development version: $NewVersion"
New-Item -Path $ProjectPath -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path $ProjectPath "icons") -ItemType Directory -Force | Out-Null
if (Test-Path $IconsTempPath) { Move-Item -Path (Join-Path $IconsTempPath "*") -Destination (Join-Path $ProjectPath "icons") -Force; Remove-Item -Path $IconsTempPath -Recurse -Force }

# --- Phase 4: Write Project Files ---

$ManifestTemplate = @'
{{
    "manifest_version": 3,
    "name": "AI-Prop-Protection",
    "version": "{0}",
    "description": "Detects propaganda sources and topics in AI chatbot responses.",
    "homepage_url": "https://github.com/King4s/ai-prop-protection.com",
    "author": "King4s",
    "permissions": ["storage", "activeTab", "scripting"],
    "background": {{ "service_worker": "background.js" }},
    "action": {{
        "default_popup": "popup.html",
        "default_icon": {{ "16": "icons/icon16.png", "48": "icons/icon48.png", "128": "icons/icon128.png" }}
    }},
    "icons": {{ "16": "icons/icon16.png", "48": "icons/icon48.png", "128": "icons/icon128.png" }},
    "host_permissions": [
        "*://*.openai.com/*", "*://chatgpt.com/*", "*://gemini.google.com/*", "*://aistudio.google.com/*",
        "*://copilot.microsoft.com/*", "*://*.bing.com/*", "*://claude.ai/*", "*://perplexity.ai/*",
        "*://*.deepseek.com/*", "*://meta.ai/*"
    ],
    "web_accessible_resources": [
        {{ "resources": ["domains.json", "keywords.json"], "matches": ["<all_urls>"] }}
    ]
}}
'@
$ManifestContent = $ManifestTemplate -f $NewVersion

$ContentJsContent = @'
// --- AI-Prop-Protection: Universal Content Script ---
let DOMAINS_LIST = [];
let KEYWORDS_LIST = [];
let SCANNED_ELEMENTS = new WeakSet();

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.action === "executeScan") {
        initializeAndScan();
    }
    return true;
});

async function initializeAndScan() {
    const domainsData = await fetchData('domains.json');
    const keywordsData = await fetchData('keywords.json');
    DOMAINS_LIST = domainsData.domains || [];
    KEYWORDS_LIST = keywordsData.keywords || [];
    
    SCANNED_ELEMENTS = new WeakSet();
    chrome.runtime.sendMessage({ action: "resetThreatCount" });
    performBruteForceScan();
}

function performBruteForceScan() {
    const allElements = document.querySelectorAll('p, div, span, td, li');
    Array.from(allElements).forEach(el => {
        if (el.innerText && el.innerText.length > 40 && !el.querySelector('p, div')) {
            if (!SCANNED_ELEMENTS.has(el)) {
                 scanSingleElement(el);
                 SCANNED_ELEMENTS.add(el);
            }
        }
    });
}

function scanSingleElement(element) {
    const text = element.innerText.toLowerCase();
    if (!text) return;
    for (const domain of DOMAINS_LIST) {
        if (text.includes(domain)) {
            createWarningBanner(domain, element, 'domain');
            chrome.runtime.sendMessage({ action: "threatDetected" });
            return;
        }
    }
    for (const keyword of KEYWORDS_LIST) {
        if (text.includes(keyword)) {
            createWarningBanner(keyword, element, 'keyword');
            return;
        }
    }
}

async function fetchData(fileName) {
    try {
        const response = await fetch(chrome.runtime.getURL(fileName));
        return (await response.json()) || {};
    } catch (error) {
        console.error(`AIPP Error: ${error}`);
        return {};
    }
}

function createWarningBanner(foundItem, messageElement, type) {
    const existingBanner = messageElement.querySelector('.ai-prop-protection-warning');
    if (existingBanner && existingBanner.dataset.type === 'domain') return;
    if (existingBanner) existingBanner.remove();
    const banner = document.createElement('div');
    banner.className = 'ai-prop-protection-warning';
    banner.dataset.type = type;
    if (type === 'domain') {
        banner.style.backgroundColor = '#ff4d4d';
        banner.style.border = '2px solid #cc0000';
        banner.innerHTML = `⚠️ **AIPP WARNING** ⚠️<br>This response may directly cite a source (${foundItem}) linked to a known disinformation network.`;
    } else {
        banner.style.backgroundColor = '#ffc107';
        banner.style.border = '2px solid #d39e00';
        banner.innerHTML = `💡 **AIPP CONTEXT-AWARENESS** 💡<br>This conversation mentions a known propaganda entity ("${foundItem}"). Please remain critical of the information presented.`;
    }
    banner.style.color = 'black';
    banner.style.padding = '10px';
    banner.style.margin = '10px 0 0 0';
    banner.style.borderRadius = '8px';
    banner.style.fontWeight = 'bold';
    messageElement.append(banner);
}
'@

$BackgroundJsContent = @'
let threatCounts = {};
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    const tabId = sender.tab.id;
    if (request.action === "threatDetected") {
        threatCounts[tabId] = (threatCounts[tabId] || 0) + 1;
        chrome.action.setBadgeText({ text: threatCounts[tabId].toString(), tabId: tabId });
        chrome.action.setBadgeBackgroundColor({ color: '#FF0000', tabId: tabId });
    } else if (request.action === "resetThreatCount") {
        threatCounts[tabId] = 0;
        chrome.action.setBadgeText({ text: '', tabId: tabId });
    }
});
chrome.tabs.onRemoved.addListener((tabId) => { delete threatCounts[tabId]; });
chrome.tabs.onReplaced.addListener((addedTabId, removedTabId) => { delete threatCounts[removedTabId]; });
'@

$PopupHtmlContent = @'
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: sans-serif; width: 220px; text-align: center; padding: 10px; background-color: #2b2b2b; color: white;}
        button { background-color: #007bff; color: white; border: none; padding: 10px 20px; font-size: 14px; border-radius: 5px; cursor: pointer; transition: background-color 0.2s; }
        button:hover { background-color: #0056b3; }
        p { font-size: 12px; color: #aaa; }
    </style>
</head>
<body>
    <h3>AI-Prop-Protection</h3>
    <button id="scanButton">Scan Page Now</button>
    <p>Scans the page for propaganda sources and keywords.</p>
    <script src="popup.js"></script>
</body>
</html>
'@

$PopupJsContent = @'
document.getElementById('scanButton').addEventListener('click', () => {
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
        if (tabs.length === 0) return;
        const activeTab = tabs[0];
        
        console.log("AIPP Popup: Injecting script into tab " + activeTab.id);
        chrome.scripting.executeScript({
            target: { tabId: activeTab.id, allFrames: true },
            files: ['content.js']
        }, () => {
            if (chrome.runtime.lastError) {
                console.error("Injection failed:", chrome.runtime.lastError.message);
                return;
            }
            setTimeout(() => {
                chrome.tabs.sendMessage(activeTab.id, { action: "executeScan" });
            }, 100);
        });
    });
});
'@

$DomainsJsonContent = @'
{
    "version": 0.3,
    "domains": [ "alalamtv.net", "almasirah.com", "geopolitics.news", "globalresearch.ca", "infowars.com", "naturalnews.com", "news-front.info", "news-lenta.com", "orientalreview.org", "pravda-en.com", "presstv.ir", "real-info.pro", "remix-news.com", "rrn.world", "rt.com", "rybar.ru", "southfront.org", "sputnikglobe.com", "sputniknews.com", "strategic-culture.su", "tass.com", "w-n-n.com", "waronfakes.com" ]
}
'@

$KeywordsJsonContent = @'
{
    "version": 0.1,
    "keywords": [ "rt ", "russia today", "sputnik news", "waronfakes", "war on fakes", "infowars", "new eastern outlook", "strategic culture foundation", "newsfront", "southfront", "global research", "presstv", "press tv", "al-alam", "al-masirah", "oriental review" ]
}
'@

# --- Write All Files ---
Write-Host "-> Writing all project files for new version: $NewVersion"
$fileList = @{
    "manifest.json" = $ManifestContent
    "content.js" = $ContentJsContent
    "background.js" = $BackgroundJsContent
    "popup.html" = $PopupHtmlContent
    "popup.js" = $PopupJsContent
    "domains.json" = $DomainsJsonContent
    "keywords.json" = $KeywordsJsonContent
}
foreach ($file in $fileList.GetEnumerator()) {
    Set-Content -Path (Join-Path $ProjectPath $file.Name) -Value $file.Value -Encoding UTF8
}
Write-Host "   All files written successfully."

# --- Phase 5: GitHub Release ---
Write-Host ""
$releaseChoice = Read-Host "-> Do you want to create a new release on GitHub for version v$NewVersion? [Y/N]"
if ($releaseChoice -eq 'Y') {
    Write-Host "   Starting GitHub release process..."
    $commitMessage = "Build and release v$NewVersion"
    $tagName = "v$NewVersion"
    $releaseNotes = "This release implements the Universal Scan Engine architecture. All platforms are now scanned using a robust, manually-triggered brute-force method, eliminating platform-specific selectors and improving reliability."
    
    $FinalZipFileName = "${ProjectName}_v${NewVersion}.zip"
    $FinalZipFullPath = Join-Path $BackupDirPath $FinalZipFileName
    Compress-Archive -Path "$ProjectPath\*" -DestinationPath $FinalZipFullPath -Force

    Set-Location $ProjectParentPath
    git add .
    git commit -m $commitMessage
    git tag $tagName
    git push
    git push --tags
    gh release create $tagName "$FinalZipFullPath" --title $commitMessage --notes $releaseNotes
    
    Write-Host ""
    Write-Host "SUCCESS: Release $tagName has been created on GitHub!" -ForegroundColor Green
    $repoUrl = git remote get-url origin
    if ($repoUrl.StartsWith("https:")) {
        $releaseUrl = $repoUrl.Replace(".git", "/releases/tag/$tagName")
        Write-Host "You can view it at: $releaseUrl"
    }
} else {
    Write-Host "Skipping GitHub release. Your local build is ready for testing." -ForegroundColor Yellow
}
Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "     BUILD & RELEASE PIPELINE COMPLETE"
Write-Host "====================================================" -ForegroundColor Green
Write-Host ""