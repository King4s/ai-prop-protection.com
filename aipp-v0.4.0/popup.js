document.getElementById('scanButton').addEventListener('click', () => {
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
        // Send a message to the content script in the active tab
        chrome.tabs.sendMessage(tabs[0].id, { action: "manualScan" });
    });
});