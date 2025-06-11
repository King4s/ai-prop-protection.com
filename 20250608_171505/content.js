// --- AI-Prop-Protection: CANARY SCRIPT ---
// Purpose: To test if a script is injected and can receive messages.

console.log(`[AIPP Canary] Content Script INJECTED and ALIVE on ${window.location.hostname}.`);

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    console.log('[AIPP Canary] Message received from popup!', request);
    if (request.action === "manualScan") {
        console.log('[AIPP Canary] Manual scan action was correctly identified.');
        // Visually confirm that the script is running by changing the background color
        document.body.style.backgroundColor = '#282A36'; 
        alert('AIPP Canary: Connection to Content Script Successful!');
    }
    return true; // Acknowledge message receipt
});

console.log('[AIPP Canary] Message listener is now active.');
