<h2 align="center">
  <img src="https://github.com/notcandy001/Moonveil-asset/blob/main/moonvile.jpeg" alt="Logo"/><br><br>
  Moonveil for Hyprland
</h2>

<h3 align="center">
  A quiet, moonlit Hyprland environment
</h3>

<h4 align="center">
  <a href="https://github.com/notcandy001/my-wal">Wallpaper collection</a>
</h4>

> [!NOTE]  
> Designed for writers, night owls, and minimalists.

> [!CAUTION]  
> Requires [Matugen](https://github.com/InioX/matugen) to function correctly.

<h3 align="center">
  ✨ A Poetic, Minimal Hyprland Rice ✨
</h3>

---

## Features
- Clean and distraction-free layout  
- Smooth, subtle animations  
- Carefully tuned keybindings  
- Minimal yet expressive UI  
- Writer-focused workflow  
- Easy to customize  

---

## Screenshots

<details>
<summary>🎨 Rofi</summary>

<h4 align="center">Launcher</h4>

![Rofi Launcher](https://github.com/notcandy001/Moonveil-asset/blob/main/2026-01-08_22-00-57.png)

</details>

<details>
<summary>🧭 Waybar</summary>

![Waybar](https://github.com/notcandy001/Moonveil-asset/blob/main/2026-01-08_22-09-51.png)  
![Waybar](https://github.com/notcandy001/Moonveil-asset/blob/main/2026-01-08_22-06-44.png)

</details>

<details>
<summary>🔒 Wlogout</summary>

![Wlogout](https://github.com/notcandy001/Moonveil-asset/blob/main/2026-01-08_22-09-11.png)

</details>

<details>
<summary>🔔 SwayNC</summary>

![SwayNC](https://github.com/notcandy001/Moonveil-asset/blob/main/2026-01-08_22-11-29.png)

</details>

---

## Required Packages

<details>
<summary>📦 Dependencies</summary>

Moonveil relies on a small, intentional set of tools.  
Install the following packages for the setup to work as intended.

### Core
- **Hyprland** – Wayland compositor  
- **Matugen** – Dynamic color generation (**required**)  
- **Waybar** – Status bar  
- **Rofi** – Application launcher  
- **Hyprlock** – Lock screen  
- **Wlogout** – Logout / power menu  
- **SwayNC** – Notification center  

### Utilities
- **Zsh** – Default shell  
- **Eza** – Modern `ls` replacement  
- **Grim** – Screenshot utility  
- **Nautilus** – File manager  
- **Pavucontrol** – Audio control  

### Theming & Appearance
- **GTK Themes** (e.g. `adw-gtk3`, custom themes)  
- **LXAppearance** – GTK theme manager  
- **Bibata Modern Ice** – Cursor theme  

### Package Management
- **yay** – AUR helper  

> ⚠️ Without **Matugen**, colors and accents will not update dynamically.

</details>

---

## Fonts

<details>
<summary>🔤 Fonts Used</summary>

Moonveil’s typography is chosen for clarity, mood, and long writing sessions.

### Required Fonts
- **Geist Mono (OTF)** – Primary UI & terminal font  
- **Geist Mono Nerd Font** – Icon support  
- **PP Neue Machina** – Display / clock font  
- **JetBrainsMono Nerd Font** – Symbols & fallback  

### Install (Arch Linux)
```bash
sudo pacman -S ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
yay -S otf-geist-mono
fc-cache -fv
