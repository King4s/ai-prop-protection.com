document.getElementById('injectAndScanButton').addEventListener('click', () => {
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
        if (tabs.length === 0) {
            console.error("No active tab found.");
            return;
        }
        const activeTab = tabs[0];

        // --- Step 1: Programmatically inject the content script ---
        chrome.scripting.executeScript({
            target: { tabId: activeTab.id },
            files: ['content.js']
        }, (injectionResults) => {
            if (chrome.runtime.lastError) {
                console.error("Script injection failed:", chrome.runtime.lastError.message);
                alert("INJECTION FAILED: " + chrome.runtime.lastError.message);
                return;
            }
            console.log("Script injection successful. Now sending message...");

            // --- Step 2: Send a message to the newly injected script ---
            chrome.tabs.sendMessage(activeTab.id, { action: "manualScan" }, (response) => {
                if (chrome.runtime.lastError) {
                    console.error("Could not send message after injection:", chrome.runtime.lastError.message);
                    alert("ERROR: The script was injected, but could not receive the message.\n\nDetails: " + chrome.runtime.lastError.message);
                } else {
                    console.log("Message sent and received by the content script!");
                }
            });
        });
    });
});
