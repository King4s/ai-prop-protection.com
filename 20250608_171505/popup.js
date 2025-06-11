document.getElementById('scanButton').addEventListener('click', () => {
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
        if (tabs.length === 0) {
            console.error("No active tab found.");
            return;
        }
        const activeTabId = tabs[0].id;
        chrome.tabs.sendMessage(activeTabId, { action: "manualScan" }, (response) => {
            if (chrome.runtime.lastError) {
                console.error("Could not send message:", chrome.runtime.lastError.message);
                alert("ERROR: Could not connect to the content script. \n\nIs the page fully reloaded after installing the extension?\n\nDetails: " + chrome.runtime.lastError.message);
            } else {
                console.log("Message sent successfully and received by content script.");
            }
        });
    });
});
