# AI-Prop-Protection

> **🛡️ An open-source tool to detect and expose AI-generated propaganda in your chats.**

This project is a browser extension that helps users identify potential state-sponsored propaganda within AI chatbot conversations. It works by scanning AI-generated responses for citations or mentions of domains known to be part of disinformation networks.

> **Status:** MVP (Minimum Viable Product). Currently supports ChatGPT on Google Chrome.

---

## How It Works

The plugin runs locally in your browser and contains a predefined list of disinformation domains. When you are conversing with ChatGPT, the plugin monitors the AI's responses. If a response contains text matching a domain from the list, a clear warning banner is displayed directly above the compromised message.

**Your privacy is paramount. No conversation data ever leaves your computer.**

## Installation (for Testing)

The project is not yet on the Chrome Web Store. You can load it for testing directly from this repository:

1.  **Download the code:** Go to the main page of this repository (`https://github.com/King4s/ai-prop-protection.com`) and click the green `Code` button, then `Download ZIP`.
2.  **Unzip the file:** Unzip the downloaded file on your computer. You will have a folder containing `manifest.json` and the other project files.
3.  **Open Chrome Extensions:** Open Google Chrome and navigate to `chrome://extensions`.
4.  **Enable Developer Mode:** In the top-right corner, turn on the "Developer mode" toggle.
5.  **Load the Extension:** Click the `Load unpacked` button and select the entire folder you unzipped in step 2.
6.  The **AI-Prop-Protection** icon will now appear in your browser's toolbar. It is now active and ready to be tested on the ChatGPT website.

## Future Goals
*   Automate the `domains.json` list so it can be updated from a central source.
*   Add support for other LLM chatbots (e.g., Google Gemini, Anthropic Claude).
*   Implement more advanced detection, such as identifying propaganda *narratives*, not just sources.

## How to Contribute

This is an open-source project, and contributions are welcome! Please feel free to open an "Issue" to report bugs or suggest features, or submit a "Pull Request" to contribute code.

## License

This project is licensed under the **MIT License**. See the `LICENSE` file for details.