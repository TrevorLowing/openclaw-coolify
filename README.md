# Moltbot (Coolify Edition)

This is a production-grade setup for running **Moltbot**—your personal agentic coding assistant—on Coolify. It supports multi-agent workflows, Docker sandboxing, and integration with WhatsApp, Telegram, and more.

## 🚀 Easy Setup on Coolify

1.  Open your Coolify Dashboard.
2.  Navigate to **Project** > **New**.
3.  Select **Public Repository**.
4.  Enter the URL: `https://github.com/essamamdani/moltbot-coolify`
5.  Click **Continue**.

---

## 🛠️ Environment Configuration

Before deploying, configure your **Environment Variables** in Coolify. These keys unlock different AI models and features.

### Required
| Variable | Description |
| :--- | :--- |
| `OPENAI_API_KEY` | Required for many core reasoning tasks (OpenAI models). |
| `ANTHROPIC_API_KEY` | Unlocks Claude 3.5 Sonnet / Opus (highly recommended for coding). |

### Optional (Recommended)
| Variable | Description |
| :--- | :--- |
| `MINIMAX_API_KEY` | Unlocks MiniMax M2.1 models (great performance/price). |
| `GEMINI_API_KEY` | Google Gemini models. |
| `KIMI_API_KEY` | Kimi / Moonshot AI models. |
| `TELEGRAM_BOT_TOKEN` | If using Telegram (see Channel Setup below). |

### Advanced
| Variable | Description |
| :--- | :--- |
| `MOLTBOT_GATEWAY_PORT` | Internal port (Default: `18789`). Only change if needed. |
| `CF_TUNNEL_TOKEN` | Optional. Cloudflare Tunnel token for exposing agent-created apps. |
| `VERCEL_TOKEN` | Optional. For deploying apps to Vercel (`vercel deploy --token ...`). |
| `GITHUB_TOKEN` | Optional. For creating repos and pushing code (`gh auth login --with-token`). |

> **Pro Tip**: You can simply copy the contents of [.env.example](.env.example) into Coolify's bulk edit view.

---

## 📦 Lifecycle & Installation

### 1. Pre-request (Build)
When you click **Deploy**, Coolify builds your custom Docker image.
- **Base**: `ubuntu:24.04`
- **Installs**: `curl`, `git`, `python3` (with `uv`), `golang-go`.
- **Power Tools**: `ripgrep` (rg), `fd`, `fzf`, `bat`, `jq`.
- **Runtimes**: `bun`, `yarn`, `npm`.
- **Moltbot**: Downloads and installs the latest binary via `install.sh`.

### 2. Pre-install (Bootstrap)
The container starts with `bootstrap.sh`.
- **Config**: Generates `~/.moltbot/moltbot.json` if missing.
- **Migration**: Renames old `clawdbot.json` to `moltbot.json` if found.
- **Sandboxing**: Configures Docker sandboxing (see `SOUL.md` for safety rules).

### 3. Post-install (Ready)
Once running, check the **Service Logs** in Coolify.
- Look for: `🦞 MOLTBOT READY`
- You will see a **Dashboard URL** with a token (e.g., `http://.../?token=xyz`).
- **Click that link** to access your Moltbot Gateway UI.

---

## 💬 Channel Setup

Moltbot lives where you work. You can connect it to WhatsApp, Telegram, Discord, etc.

### 📱 Telegram
**Fastest setup.**
1.  Talk to **@BotFather** on Telegram.
2.  Create a new bot (`/newbot`) and get the **Token**.
3.  Add `TELEGRAM_BOT_TOKEN` to your Coolify Environment Variables.
4.  **Redeploy** (or just restart).
5.  DM your new bot. It will ask for a **Pairing Code**.
6.  Go to your Moltbot Dashboard > **Pairing** to approve it.
    *   *Docs: [Telegram Channel Guide](docs/channels/telegram.md)*

### 🟢 WhatsApp
**Requires scanning a QR code.**
1.  Go to your Moltbot Dashboard (from the logs).
2.  Navigate to **Channels** > **WhatsApp**.
3.  Open WhatsApp on your phone > **Linked Devices** > **Link a Device**.
4.  Scan the QR code shown on the dashboard.
5.  **Done!** You can now chat with Moltbot.
    *   *Docs: [WhatsApp Channel Guide](docs/channels/whatsapp.md)*

### ⚡ Other Channels
You can verify status or manage other channels (Discord, Slack) via the dashboard or CLI.
*   *CLI Docs: [Channel Management](docs/cli/channels.md)*

---

## 🔒 Security & Sandboxing

- **Authentication**: Dashboard is token-protected. New chat users must be "paired" (approved) first.
- **Docker Proxy**: This setup uses a **Sockety Proxy (Sidecar)** pattern.
    - Moltbot talks to a restricted Docker API proxy (`tcp://docker-proxy:2375`).
    - **Blocked**: Swarm, Secrets, System, Volumes, and other critical host functions.
    - **Allowed**: Only what's needed for sandboxing (Containers, Images, Networks).
- **Isolation**: Sub-agents run in disposable containers. `SOUL.md` rules forbid the agent from touching your other Coolify services.