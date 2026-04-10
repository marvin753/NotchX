<h1 align="center">
  <br>
  <img src="https://framerusercontent.com/images/RFK4vs0kn8pRMuOO58JeyoemXA.png?scale-down-to=256" alt="NotchX" width="150">
  <br>
  NotchX
  <br>
</h1>

Meet **NotchX** — a Dynamic Island-style interface for every MacBook with a notch. Instead of wasting that black cutout at the top of your screen, NotchX transforms it into an always-available command center: glanceable at a glance, expandable on demand, and completely out of your way when you don't need it.

Expand the notch to access Now Playing controls with a rich music visualizer, your upcoming Calendar events, a Shelf with AirDrop support, system HUD replacements for volume and brightness, a Focus Timer to keep you locked in, Bluetooth device management, a fullscreen Teleprompter mode, and more — all wrapped in a frosted-glass interface that feels like it belongs on macOS.

<p align="center">
  <!-- TODO: Replace with your own demo GIF -->
  <img src="https://github.com/user-attachments/assets/2d5f69c1-6e7b-4bc2-a6f1-bb9e27cf88a8" alt="NotchX Demo" />
</p>

---

## Installation

**System Requirements:**
- macOS **14 Sonoma** or later
- MacBook with a built-in notch display
- Apple Silicon or Intel Mac

---

### Option 1: Download and Install Manually

<a href="https://github.com/MarvinBarsal/NotchX/releases/latest/download/NotchX.dmg" target="_self"><img width="200" src="https://github.com/user-attachments/assets/e3179be1-8416-4b8a-b417-743e1ecc67d6" alt="Download for macOS" /></a>

Once downloaded, open the `.dmg` and move **NotchX** to your `/Applications` folder.

> [!IMPORTANT]
> NotchX is currently unsigned, so macOS will show a security warning on first launch. This is expected — you only need to bypass it once.
>
> Use one of the methods below to open the app.

---

#### Recommended: Terminal (Always Works)

After moving NotchX to your Applications folder, run:

```bash
xattr -dr com.apple.quarantine /Applications/NotchX.app
```

Then open the app normally.

---

#### Alternative: System Settings

> [!NOTE]
> This method doesn't work for all users. If it fails, use the Terminal method above.

1. Try to open the app — you'll see a security warning.
2. Click **OK** to dismiss it.
3. Open **System Settings** > **Privacy & Security**.
4. Scroll down and click **Open Anyway** next to the NotchX warning.
5. Confirm if prompted.

---

### Option 2: Install via Homebrew

```bash
brew install --cask MarvinBarsal/notchx/notchx --no-quarantine
```

---

## Usage

- Launch NotchX — it runs silently in the background with no Dock icon or menu bar clutter.
- **Hover** over the notch to expand it and reveal the full interface.
- **Click** or **two-finger swipe** on the notch to toggle between modules.
- Open **Settings** to configure modules, gestures, and visual preferences.

---

## Building from Source

### Prerequisites

- **macOS 14 or later**
- **Xcode 16 or later**

### Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/MarvinBarsal/NotchX.git
   cd NotchX
   ```

2. **Open in Xcode:**
   ```bash
   open NotchX.xcodeproj
   ```

3. **Build and run:**  
   Press `Cmd + R` or click the Run button.

---

## 🤝 Contributing

Contributions are welcome! Read [CONTRIBUTING.md](CONTRIBUTING.md) to get started.

---

## Notable Projects

NotchX builds on the shoulders of some great open-source work:

- **[MediaRemoteAdapter](https://github.com/ungive/mediaremote-adapter)** — Enables the Now Playing source on macOS 15.4+.
- **[NotchDrop](https://github.com/Lakr233/NotchDrop)** — Provided the foundation for the Shelf feature.

For a full list of licenses and attributions, see [THIRD_PARTY_LICENSES.md](./THIRD_PARTY_LICENSES.md).
