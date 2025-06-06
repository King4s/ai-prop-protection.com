// --- AI-Prop-Protection: content.js v0.1.1 ---

/**
 * Fetches the list of disinformation domains from the local JSON file.
 * @returns {Promise<string[]>} A promise that resolves to an array of domain strings.
 */
async function getDisinformationDomains() {
  try {
    const response = await fetch(chrome.runtime.getURL('domains.json'));
    if (!response.ok) {
      console.error("AI-Prop-Protection: Could not fetch domains.json. Status:", response.status);
      return [];
    }
    const data = await response.json();
    return data.domains || [];
  } catch (error) {
    console.error("AI-Prop-Protection: Error loading or parsing domains.json:", error);
    return [];
  }
}

/**
 * Creates the warning banner element to be injected into the page.
 * @param {string} foundDomain - The domain that was detected.
 * @returns {HTMLElement} The warning banner element.
 */
function createWarningBanner(foundDomain) {
  const banner = document.createElement('div');
  banner.style.backgroundColor = '#ff4d4d';
  banner.style.color = 'white';
  banner.style.padding = '10px';
  banner.style.margin = '10px 0';
  banner.style.borderRadius = '8px';
  banner.style.border = '2px solid #cc0000';
  banner.style.fontWeight = 'bold';
  banner.innerHTML = `⚠️ **AI-PROP-PROTECTION WARNING** ⚠️<br>This response may cite or reference a source (${foundDomain}) linked to a known disinformation network. Please verify this information with trusted sources.`;
  return banner;
}

/**
 * Scans a given element for any of the domains in our list.
 * @param {HTMLElement} element - The HTML element containing the AI's response.
 * @param {string[]} domains - The list of disinformation domains.
 */
function scanElementForDomains(element, domains) {
  const text = element.innerText.toLowerCase();
  if (!text) return;

  for (const domain of domains) {
    if (text.includes(domain)) {
      if (!element.dataset.propWarned) {
        console.log(`AI-Prop-Protection: Found suspicious domain: ${domain}`);
        const banner = createWarningBanner(domain);
        element.dataset.propWarned = 'true'; // Mark as warned to prevent duplicate banners
        element.prepend(banner);
        break; 
      }
    }
  }
}

/**
 * Main execution function.
 * Sets up the MutationObserver to watch for new messages.
 */
async function main() {
  const domains = await getDisinformationDomains();
  if (domains.length === 0) {
    console.log("AI-Prop-Protection: No domains to scan. Exiting.");
    return;
  }

  console.log(`AI-Prop-Protection: Loaded ${domains.length} domains. Starting observer.`);

  const observer = new MutationObserver((mutationsList) => {
    for (const mutation of mutationsList) {
      mutation.addedNodes.forEach(node => {
        if (node.nodeType === Node.ELEMENT_NODE) {
          const assistantMessages = node.querySelectorAll('[data-message-author-role="assistant"]');
          assistantMessages.forEach(msg => {
            const textContainer = msg.querySelector('.prose'); // This is where ChatGPT's main text lives
            if (textContainer) {
              scanElementForDomains(textContainer, domains);
            }
          });
        }
      });
    }
  });

  observer.observe(document.body, { childList: true, subtree: true });
}

main();