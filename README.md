# AI-Prop-Protection

[![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg)](https://github.com/King4s/ai-prop-protection.com/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/King4s/ai-prop-protection.com/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Chrome%20%7C%20Firefox%20(Soon)-orange.svg)](https://github.com/King4s/ai-prop-protection.com)

**An open-source browser extension to detect and expose potential propaganda in AI chatbot responses.**

AI-Prop-Protection helps you stay critical in the age of AI by scanning conversations for known disinformation sources and keywords. When a potential threat is found, it displays a clear, non-intrusive warning, empowering you to evaluate the information more carefully.

## Core Features

-   **Universal Scan Engine:** A single, robust scanning engine that works across multiple AI platforms.
-   **Dual-Threat Detection:** Scans for both direct links to known disinformation **domains** (red warning) and mentions of propaganda-related **keywords** (yellow warning).
-   **User-Controlled & Private:** The extension is 100% manually triggered via the toolbar button. No automatic scanning occurs. All analysis happens locally on your computer, and no data is ever collected or transmitted.
-   **Persistent Alerts:** A badge on the extension icon keeps a running count of severe threats found, ensuring you never miss a critical warning, even on long pages.

## Supported Platforms

This extension is designed to work on a wide range of popular LLM chat interfaces. The current version has been confirmed to work on:

-   **OpenAI ChatGPT** (`chatgpt.com`)
-   **Google Gemini** (`gemini.google.com`)
-   **Google AI Studio** (`aistudio.google.com`)
-   **Microsoft Copilot** (`copilot.microsoft.com` / `bing.com`)
-   **Anthropic Claude** (`claude.ai`)
-   **Perplexity AI** (`perplexity.ai`)
-   **DeepSeek** (`chat.deepseek.com`)
-   **Meta AI** (`meta.ai`)

## Installation

This extension is currently pending review on the Chrome Web Store. Until then, you can install it manually from the latest GitHub release.

1.  **Download the Release:** Go to the [**Releases Page**](https://github.com/King4s/ai-prop-protection.com/releases) on GitHub. Find the latest release (e.g., `v1.0.0`) and download the `.zip` file (e.g., `ai-prop-protection_v1.0.0.zip`).
2.  **Unzip the File:** Unzip the downloaded file into a permanent folder on your computer (e.g., `C:\Tools\AIPP`).
3.  **Open Chrome Extensions:** Open your Chrome browser and navigate to `chrome://extensions`.
4.  **Enable Developer Mode:** In the top-right corner, turn on the "Developer mode" toggle.
5.  **Load the Extension:** Click the **"Load unpacked"** button and select the unzipped `ai-prop-protection` folder from step 2.

The extension is now installed and ready to use.

## How to Use

1.  Navigate to any of the supported AI chatbot websites.
2.  Have a conversation with the AI.
3.  When you want to check the response for propaganda, click the **AI-Prop-Protection icon** in your browser's toolbar.
4.  Click the **"Scan Page Now"** button.
5.  The extension will scan the page and display warnings if any matches are found.

## How to Contribute

This is an open-source project, and contributions are highly welcome. Whether it's suggesting new domains/keywords, improving the code, or adding support for more platforms, please feel free to:

-   [Open an Issue](https://github.com/King4s/ai-prop-protection.com/issues) to report bugs or suggest features.
-   [Submit a Pull Request](https://github.com/King4s/ai-prop-protection.com/pulls) to contribute code.

## License

This project is licensed under the **MIT License**. See the [LICENSE](https://github.com/King4s/ai-prop-protection.com/blob/main/LICENSE) file for details.
