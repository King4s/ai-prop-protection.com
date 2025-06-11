// --- AI-Prop-Protection: INJECTED CANARY SCRIPT ---
console.log(`[AIPP Canary] Content Script has been PROGRAMMATICALLY INJECTED into ${window.location.hostname}.`);
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    console.log('[AIPP Canary] Message received from popup!', request);
    if (request.action === "manualScan") {
        console.log('[AIPP Canary] Manual scan action was correctly identified.');
        alert('SUCCESS! The popup successfully connected to the injected script.');
    }
    return true;
});
console.log('[AIPP Canary] Message listener is now active.');
