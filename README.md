<div align="center">

<br/>

```
███╗   ███╗███████╗██████╗ ██╗   ██╗ █████╗ ███╗   ██╗
████╗ ████║██╔════╝██╔══██╗██║   ██║██╔══██╗████╗  ██║
██╔████╔██║█████╗  ██████╔╝██║   ██║███████║██╔██╗ ██║
██║╚██╔╝██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══██║██║╚██╗██║
██║ ╚═╝ ██║███████╗██║  ██║ ╚████╔╝ ██║  ██║██║ ╚████║
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═══╝
        S  E  R  V  I  C  E  S
```

**v1.0** — Signal Listener for Roblox

[![Discord](https://img.shields.io/badge/Discord-.gg%2Fmervan-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/mervan)
[![Roblox](https://img.shields.io/badge/Platform-Roblox-E8462A?style=for-the-badge&logo=roblox&logoColor=white)](https://roblox.com)
[![Lua](https://img.shields.io/badge/Language-Lua-2C2D72?style=for-the-badge&logo=lua&logoColor=white)](https://lua.org)

</div>

---

## ✦ What is Mervan Services?

**Mervan Services** is a premium Roblox signal listener tool — it monitors `RemoteEvent`, `RemoteFunction`, and `BindableEvent` signals in real time, lets you pin your favourites, and lets you fire them with a single click. Built with a sleek dark UI and a signature purple accent theme.

---

## 🚀 Quick Start

Paste the loader into your executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/APZXCORE/Mervan-Script/main/mervan.lua"))()
```

> **Need a key?** Join **[discord.gg/mervan](https://discord.gg/mervan)** to get yours.

---

## 🎮 Usage

| Action | PC | Mobile |
|---|---|---|
| Toggle UI | `RightShift` | `S Button` |
| Fire Signal | Click signal row | Tap signal row |
| Quick Fire | Set hotkey in Settings | — |
| Pin Signal | Click pin icon | Tap pin icon |

### Tabs

- **Listener** — Live feed of all detected signals with fire controls
- **Pinned** — Your saved/favourited signals, persist across sessions
- **Settings** — Keybinds, signal speed, product name display, detach

---

## 📁 File Structure

```
Mervan-Script/
├── mervan.lua          ← Main script (UI + logic)
├── loader.lua          ← One-line executor loadstring
├── legacy.lua          ← Legacy support module
├── hubbeta.lua         ← Hub beta module
└── README.md
```

---

## ✨ Features

- 🟣 **Signature purple theme** — deep dark UI with vivid purple accents
- 📡 **Real-time signal listener** — catches Remote/Bindable events live
- 📌 **Pinned signals** — save your most-used signals across sessions
- ⚡ **Quick fire hotkey** — bind any key to instantly fire the latest signal
- 🔑 **Key system** — auto-saves your key after first login
- 📱 **Mobile support** — fully responsive layout for mobile executors
- 🎨 **Glowing UI borders** — premium UIStroke effects on all panels
- 🔇 **Suppress system** — filter out spam signals automatically

---

## ⚙️ Settings

| Setting | Description |
|---|---|
| Toggle Keybind | Change the hotkey to show/hide the UI |
| Quick Fire Hotkey | Bind a key to instantly fire the last detected signal |
| Signals per Second | Control the auto-fire rate |
| Show Product Names | Display product names from MarketplaceService |

---

## 🔑 Key System

Keys are stored locally in `mervan_key.txt` — you only need to enter your key once. If your key ever stops working, rejoin **[discord.gg/mervan](https://discord.gg/mervan)** for a replacement.

---

## 📋 Requirements

- A Roblox executor that supports `HttpGet`, `writefile`, `readfile`, and `setclipboard`
- A valid Mervan Services key from our Discord

---

## 📜 Changelog

### v1.0
- Initial release of Mervan Services
- Signature purple accent theme
- Glowing UIStroke border effects
- Full rebrand with `S E R V I C E S` loading screen
- Persistent pinned signals & settings
- Mobile-first responsive layout

---

<div align="center">

**[discord.gg/mervan](https://discord.gg/mervan)** — Join for keys, updates & support

*© 2025 Mervan Services. All rights reserved.*

</div>
