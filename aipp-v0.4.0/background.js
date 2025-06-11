// --- AI-Prop-Protection: background.js v0.6.0 ---

let threatCount = 0;

// Lyt efter beskeder fra content.js
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.action === "threatDetected") {
        threatCount++;
        // Opdater badge-teksten
        chrome.action.setBadgeText({
            text: threatCount.toString(),
            tabId: sender.tab.id // Sørg for kun at opdatere badget for den relevante fane
        });
        // Sæt farven på badget
        chrome.action.setBadgeBackgroundColor({
            color: '#FF0000', // Rød farve for alarm
            tabId: sender.tab.id
        });
    } else if (request.action === "resetThreatCount") {
        threatCount = 0;
        chrome.action.setBadgeText({ text: '', tabId: sender.tab.id });
    }
});

// Nulstil tælleren, når en fane opdateres eller lukkes
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
    if (changeInfo.status === 'loading') {
        threatCount = 0;
        chrome.action.setBadgeText({ text: '', tabId: tabId });
    }
});