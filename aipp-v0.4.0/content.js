// --- AI-Prop-Protection: CANARY SCRIPT ---
// This script's only purpose is to test if it can be injected and
// if it can receive messages on a specific page.

console.log(`[AIPP Canary] Content Script INJECTED and ALIVE on ${window.location.hostname}.`);

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    console.log('[AIPP Canary] Message received from popup!', request);
    
    // Acknowledge the message to prevent errors in the popup
    if (request.action === "manualScan") {
        console.log('[AIPP Canary] Manual scan action was correctly identified.');
    }
    
    // It's good practice to return true for async responses, but here we just confirm receipt.
    return true; 
});

console.log('[AIPP Canary] Message listener is now active.');