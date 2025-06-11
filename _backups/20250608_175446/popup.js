document.getElementById('injectAndScanButton').addEventListener('click', () => {
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
        if (tabs.length === 0) return;
        const activeTab = tabs[0];
        chrome.scripting.executeScript({
            target: { tabId: activeTab.id },
            files: ['content.js']
        }, () => {
            if (chrome.runtime.lastError) {
                console.error("Injection failed:", chrome.runtime.lastError.message);
                alert("INJECTION FAILED: " + chrome.runtime.lastError.message);
                return;
            }
            chrome.tabs.sendMessage(activeTab.id, { action: "manualScan" }, () => {
                if (chrome.runtime.lastError) {
                    console.error("Message sending failed:", chrome.runtime.lastError.message);
                    alert("ERROR: Script injected, but could not receive the message.\nDetails: " + chrome.runtime.lastError.message);
                }
            });
        });
    });
});
