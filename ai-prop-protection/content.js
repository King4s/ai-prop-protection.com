// --- AI-Prop-Protection: Universal Content Script ---
let DOMAINS_LIST = [];
let KEYWORDS_LIST = [];
let SCANNED_ELEMENTS = new WeakSet();

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.action === "executeScan") {
        initializeAndScan();
    }
    return true;
});

async function initializeAndScan() {
    const domainsData = await fetchData('domains.json');
    const keywordsData = await fetchData('keywords.json');
    DOMAINS_LIST = domainsData.domains || [];
    KEYWORDS_LIST = keywordsData.keywords || [];
    
    SCANNED_ELEMENTS = new WeakSet();
    chrome.runtime.sendMessage({ action: "resetThreatCount" });
    performBruteForceScan();
}

function performBruteForceScan() {
    const allElements = document.querySelectorAll('p, div, span, td, li');
    Array.from(allElements).forEach(el => {
        if (el.innerText && el.innerText.length > 40 && !el.querySelector('p, div')) {
            if (!SCANNED_ELEMENTS.has(el)) {
                 scanSingleElement(el);
                 SCANNED_ELEMENTS.add(el);
            }
        }
    });
}

function scanSingleElement(element) {
    const text = element.innerText.toLowerCase();
    if (!text) return;
    for (const domain of DOMAINS_LIST) {
        if (text.includes(domain)) {
            createWarningBanner(domain, element, 'domain');
            chrome.runtime.sendMessage({ action: "threatDetected" });
            return;
        }
    }
    for (const keyword of KEYWORDS_LIST) {
        if (text.includes(keyword)) {
            createWarningBanner(keyword, element, 'keyword');
            return;
        }
    }
}

async function fetchData(fileName) {
    try {
        const response = await fetch(chrome.runtime.getURL(fileName));
        return (await response.json()) || {};
    } catch (error) {
        console.error(`AIPP Error: ${error}`);
        return {};
    }
}

function createWarningBanner(foundItem, messageElement, type) {
    const existingBanner = messageElement.querySelector('.ai-prop-protection-warning');
    if (existingBanner && existingBanner.dataset.type === 'domain') return;
    if (existingBanner) existingBanner.remove();
    const banner = document.createElement('div');
    banner.className = 'ai-prop-protection-warning';
    banner.dataset.type = type;
    if (type === 'domain') {
        banner.style.backgroundColor = '#ff4d4d';
        banner.style.border = '2px solid #cc0000';
        banner.innerHTML = `âš ï¸ **AIPP WARNING** âš ï¸<br>This response may directly cite a source (${foundItem}) linked to a known disinformation network.`;
    } else {
        banner.style.backgroundColor = '#ffc107';
        banner.style.border = '2px solid #d39e00';
        banner.innerHTML = `ðŸ’¡ **AIPP CONTEXT-AWARENESS** ðŸ’¡<br>This conversation mentions a known propaganda entity ("${foundItem}"). Please remain critical of the information presented.`;
    }
    banner.style.color = 'black';
    banner.style.padding = '10px';
    banner.style.margin = '10px 0 0 0';
    banner.style.borderRadius = '8px';
    banner.style.fontWeight = 'bold';
    messageElement.append(banner);
}
