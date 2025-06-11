# --- AI-Prop-Protection PowerShell Project Builder ---
# Version: 11.2 (Clean Output & Safe Icons)
# Purpose: A robust build script that ALWAYS preserves the user's icon files.

# --- Configuration ---
$WorkspacePath = $PSScriptRoot
$ProjectName = "ai-prop-protection"
$ProjectPath = Join-Path $WorkspacePath $ProjectName
$BackupDirPath = Join-Path $WorkspacePath "_build_backups"
$IconsSourcePath = Join-Path $WorkspacePath "icons"
$IconsTempPath = Join-Path $WorkspacePath "_temp_icons"
$Version = "1.0.0" # Placeholder version for the build

# --- Script Start ---
Clear-Host
Write-Host "====================================================" -ForegroundColor Green
Write-Host "     AI-Prop-Protection Project Builder"
Write-Host "====================================================" -ForegroundColor Green
Write-Host "Workspace: $WorkspacePath" -ForegroundColor Cyan
Write-Host ""

# --- Phase 1: SAFE ICON PRESERVATION ---
if (Test-Path $IconsSourcePath) {
    Write-Host "-> Found 'icons' folder in workspace. Moving to safety..." -ForegroundColor Yellow
    Move-Item -Path $IconsSourcePath -Destination $IconsTempPath -Force
}

# --- Phase 2: Backup and Clean ---
if (Test-Path $ProjectPath) {
    if (-not (Test-Path $BackupDirPath)) { New-Item $BackupDirPath -ItemType Directory -Force | Out-Null }
    $ZipFileName = "${ProjectName}_v${Version}_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
    $ZipFullPath = Join-Path $BackupDirPath $ZipFileName
    Write-Host "-> Creating ZIP backup of existing build..." -ForegroundColor Yellow
    Compress-Archive -Path "$ProjectPath\*" -DestinationPath $ZipFullPath -Force
    Remove-Item $ProjectPath -Recurse -Force
}

# --- Phase 3: Create Project Structure ---
Write-Host "-> Building structure for new development version: $Version"
New-Item -Path $ProjectPath -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path $ProjectPath "icons") -ItemType Directory -Force | Out-Null
if (Test-Path $IconsTempPath) {
    Write-Host "-> Restoring preserved icons..."
    Move-Item -Path (Join-Path $IconsTempPath "*") -Destination (Join-Path $ProjectPath "icons") -Force
    Remove-Item -Path $IconsTempPath -Recurse -Force
}

# --- Phase 4: Write Project Files ---
# (File contents are identical to the previous correct version)
$ManifestTemplate = @'
{{ "manifest_version": 3, "name": "AI-Prop-Protection", "version": "{0}", "description": "Detects propaganda sources and topics in AI chatbot responses.", "homepage_url": "https://github.com/King4s/ai-prop-protection.com", "author": "King4s", "permissions": ["storage", "activeTab", "scripting"], "background": {{ "service_worker": "background.js" }}, "action": {{ "default_popup": "popup.html", "default_icon": {{ "16": "icons/icon16.png", "48": "icons/icon48.png", "128": "icons/icon128.png" }} }}, "icons": {{ "16": "icons/icon16.png", "48": "icons/icon48.png", "128": "icons/icon128.png" }}, "host_permissions": [ "*://*.openai.com/*", "*://chatgpt.com/*", "*://gemini.google.com/*", "*://aistudio.google.com/*", "*://copilot.microsoft.com/*", "*://*.bing.com/*", "*://claude.ai/*", "*://perplexity.ai/*", "*://*.deepseek.com/*", "*://meta.ai/*" ], "web_accessible_resources": [ {{ "resources": ["domains.json", "keywords.json"], "matches": ["<all_urls>"] }} ]}}
'@
$ManifestContent = $ManifestTemplate -f $Version
$GitignoreContent=@'
*.zip
_build_backups/
_temp_icons/
_releases/
Build-AIPP.ps1
Publish-AIPP.ps1
'@; $ContentJsContent=@'
let DOMAINS_LIST=[],KEYWORDS_LIST=[],SCANNED_ELEMENTS=new WeakSet;chrome.runtime.onMessage.addListener((e,t,s)=>{if("executeScan"===e.action)return initializeAndScan(),!0});async function initializeAndScan(){const e=await fetchData("domains.json"),t=await fetchData("keywords.json");DOMAINS_LIST=e.domains||[],KEYWORDS_LIST=t.keywords||[],SCANNED_ELEMENTS=new WeakSet,chrome.runtime.sendMessage({action:"resetThreatCount"}),performBruteForceScan()}function performBruteForceScan(){const e=document.querySelectorAll("p, div, span, td, li");Array.from(e).forEach(e=>{if(e.innerText&&e.innerText.length>40&&!e.querySelector("p, div")&&!SCANNED_ELEMENTS.has(e)){scanSingleElement(e),SCANNED_ELEMENTS.add(e)}})}function scanSingleElement(e){const t=e.innerText.toLowerCase();if(t){for(const s of DOMAINS_LIST)if(t.includes(s))return createWarningBanner(s,e,"domain"),void chrome.runtime.sendMessage({action:"threatDetected"});for(const n of KEYWORDS_LIST)if(t.includes(n))return void createWarningBanner(n,e,"keyword")}}async function fetchData(e){try{const t=await fetch(chrome.runtime.getURL(e));return await t.json()||{}}catch(e){return console.error(`AIPP Error: ${e}`),{}}}function createWarningBanner(e,t,s){const n=t.querySelector(".ai-prop-protection-warning");if(n&&"domain"===n.dataset.type)return;n&&n.remove();const o=document.createElement("div");o.className="ai-prop-protection-warning",o.dataset.type=s,"domain"===s?(o.style.backgroundColor="#ff4d4d",o.style.border="2px solid #cc0000",o.innerHTML=`⚠️ **AIPP WARNING** ⚠️<br>This response may directly cite a source (${e}) linked to a known disinformation network.`):(o.style.backgroundColor="#ffc107",o.style.border="2px solid #d39e00",o.innerHTML=`💡 **AIPP CONTEXT-AWARENESS** 💡<br>This conversation mentions a known propaganda entity ("${e}"). Please remain critical of the information presented.`),o.style.color="black",o.style.padding="10px",o.style.margin="10px 0 0 0",o.style.borderRadius="8px",o.style.fontWeight="bold",t.append(o)}
'@; $BackgroundJsContent=@'
let threatCounts={};chrome.runtime.onMessage.addListener((e,t,s)=>{const n=t.tab.id;if(!n)return;if("threatDetected"===e.action)threatCounts[n]=(threatCounts[n]||0)+1,chrome.action.setBadgeText({text:threatCounts[n].toString(),tabId:n}),chrome.action.setBadgeBackgroundColor({color:"#FF0000",tabId:n});else if("resetThreatCount"===e.action)threatCounts[n]=0,chrome.action.setBadgeText({text:"",tabId:n})});chrome.tabs.onRemoved.addListener(e=>{delete threatCounts[e]});chrome.tabs.onReplaced.addListener((e,t)=>{delete threatCounts[t]});
'@; $PopupHtmlContent=@'
<!DOCTYPE html><html><head><style>body{font-family:sans-serif;width:220px;text-align:center;padding:10px;background-color:#2b2b2b;color:white}button{background-color:#007bff;color:white;border:none;padding:10px 20px;font-size:14px;border-radius:5px;cursor:pointer;transition:background-color .2s}button:hover{background-color:#0056b3}p{font-size:12px;color:#aaa}</style></head><body><h3>AI-Prop-Protection</h3><button id="scanButton">Scan Page Now</button><p>Scans the page for propaganda sources and keywords.</p><script src="popup.js"></script></body></html>
'@; $PopupJsContent=@'
document.getElementById("scanButton").addEventListener("click",()=>{chrome.tabs.query({active:!0,currentWindow:!0},e=>{if(0!==e.length){const t=e[0];console.log("AIPP Popup: Injecting script into tab "+t.id),chrome.scripting.executeScript({target:{tabId:t.id,allFrames:!0},files:["content.js"]},()=>{chrome.runtime.lastError?console.error("Injection failed:",chrome.runtime.lastError.message):setTimeout(()=>chrome.tabs.sendMessage(t.id,{action:"executeScan"}),100)})}})});
'@; $DomainsJsonContent=@'
{"version":0.3,"domains":["alalamtv.net","almasirah.com","geopolitics.news","globalresearch.ca","infowars.com","naturalnews.com","news-front.info","news-lenta.com","orientalreview.org","pravda-en.com","presstv.ir","real-info.pro","remix-news.com","rrn.world","rt.com","rybar.ru","southfront.org","sputnikglobe.com","sputniknews.com","strategic-culture.su","tass.com","w-n-n.com","waronfakes.com"]}
'@; $KeywordsJsonContent=@'
{"version":0.2,"keywords":["russia today","sputnik news","waronfakes","war on fakes","infowars","new eastern outlook","strategic culture foundation","newsfront","southfront","global research","presstv","press tv","al-alam","al-masirah","oriental review"]}
'@

# --- Write All Files ---
Write-Host "-> Writing all project files for version: $Version"
$fileList = @{ ".gitignore" = $GitignoreContent; "manifest.json" = $ManifestContent; "content.js" = $ContentJsContent; "background.js" = $BackgroundJsContent; "popup.html" = $PopupHtmlContent; "popup.js" = $PopupJsContent; "domains.json" = $DomainsJsonContent; "keywords.json" = $KeywordsJsonContent }
foreach ($file in $fileList.GetEnumerator()) { Set-Content -Path (Join-Path $ProjectPath $file.Name) -Value $file.Value -Encoding UTF8 }
Write-Host "   Build complete."
Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "     BUILD COMPLETE"
Write-Host "====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "A clean build is ready for local testing in '$ProjectPath'."