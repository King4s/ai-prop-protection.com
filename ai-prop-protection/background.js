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
