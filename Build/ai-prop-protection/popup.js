document.getElementById("scanButton").addEventListener("click", () => {
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
        if (tabs.length === 0) return;
        const activeTab = tabs[0];
        
        console.log("AIPP Popup: Injecting script into tab " + activeTab.id);
        chrome.scripting.executeScript({
            target: { tabId: activeTab.id, allFrames: true },
            files: ["content.js"]
        }, () => {
            if (chrome.runtime.lastError) {
                console.error("Injection failed:", chrome.runtime.lastError.message);
                return;
            }
            // Add a small delay to ensure the script is fully loaded before sending the message
            setTimeout(() => {
                chrome.tabs.sendMessage(activeTab.id, { action: "executeScan" });
            }, 100);
        });
    });
});
