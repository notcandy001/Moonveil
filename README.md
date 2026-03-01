<p align="center">
  <a href="https://github.com/notcandy001/Moonveil">
     <img src="https://github.com/notcandy001/Moonveil-asset/blob/main/cover.png" alt="Moonveil cover">
  </a>
</p>


<p align="center">
 <img src="https://img.shields.io/github/last-commit/notcandy001/moonveil?&style=for-the-badge&color=8D748C&logoColor=D9E0EE&labelColor=252733" />

<img src="https://img.shields.io/github/stars/notcandy001/moonveil?style=for-the-badge&logo=starship&color=AB6C6A&logoColor=D9E0EE&labelColor=252733" />

<a href="https://github.com/notcandy001/moonveil">
  <img src="https://img.shields.io/github/repo-size/notcandy001/moonveil?style=for-the-badge&label=SIZE&color=DDBB88&logo=codesandbox&logoColor=D9E0EE&labelColor=252733" />
</a>
<br>

<a href="https://github.com/notcandy001/moonveil/blob/main/LICENSE">
  <img src="https://img.shields.io/github/license/notcandy001/moonveil?style=for-the-badge&color=A1C999&logo=opensourceinitiative&logoColor=D9E0EE&labelColor=252733" />
</a>

<a href="https://github.com/notcandy001/moonveil/issues">
  <img src="https://img.shields.io/github/issues/notcandy001/moonveil?style=for-the-badge&logo=bilibili&color=5E81AC&logoColor=D9E0EE&labelColor=252733" />
</a>
</br>

</p>


<h3 align="center">
  🌙 A quiet, moonlit Hyprland environment
</h3>

<h4 align="center">
  <a href="https://github.com/notcandy001/my-wal">Wallpaper collection</a>
</h4>


> [!CAUTION]
> **Matugen is required.**  
> Moonveil relies on dynamic color generation and will not function correctly without it.

<h2 align="center">✨ Features</h2>

- Clean, distraction-free layout
- Poetic and minimal design language
- Subtle, smooth animations
- Matugen & fabric-powered dynamic colors
- Carefully tuned keybindings
- Easy to extend and customize

---

<h2>
  <sub>
    <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Camera%20with%20Flash.png" width="32" height="32" />
  </sub>
  Screenshots
</h2>

<div align="center">
  <img src="https://github.com/notcandy001/Moonveil-asset/blob/main/1.png" width="100%" />

  

  <img src="https://github.com/notcandy001/Moonveil-asset/blob/main/2.png" width="32%" />
  <img src="https://github.com/notcandy001/Moonveil-asset/blob/main/3.png" width="32%" />
  <img src="https://github.com/notcandy001/Moonveil-asset/blob/main/4.png" width="32%" />

  

  <img src="https://github.com/notcandy001/Moonveil-asset/blob/main/5.png" width="32%" />
  <img src="https://github.com/notcandy001/Moonveil-asset/blob/main/6.png" width="32%" />
  <img src="https://github.com/notcandy001/Moonveil-asset/blob/main/7.png" width="32%" />
   
  

  <img src="https://github.com/notcandy001/Moonveil-asset/blob/main/8.png" width="32%" />

</div>

---

<h2>
<sub>
<img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Package.png"
     width="25" height="25"/>
</sub>
Installation
</h2>

 ### Arch (only)

```bash
bash <(curl -sL https://moonveil-web.vercel.app/dots/stable/arch) #arch only
```
 ### Debian & ubuntu based OS (only)

```bash
bash <(curl -sL https://moonveil-web.vercel.app/dots/stable/debian) 
```



## Required Packages

<details>
<summary>📦 Dependencies</summary>

Moonveil relies on a small, intentional set of tools.  
Install the following packages for the setup to work as intended.

## 📦 Pacman Packages
### Core
- **Hyprland** – Wayland compositor
- **Waybar** – Status bar
- **Rofi** – Application launcher
- **Hyprlock** – Lock screen
- **Wlogout** – Logout / power menu
- **SwayNC** – Notification center
- **gnome-bluetooth-3.0**
- **vte3**
- **imagemagick**

### Shell & CLI
- **Zsh** – Default shell
- **power-profiles-daemon**

### Utilities
- **Grim** – Screenshot utility
- **Nautilus** – File manager
- **Pavucontrol** – Audio control

### Theming & Appearance
- **LXAppearance** – GTK theme manager

### Python Dependencies
- **python**
- **python-gobject**
- **python-psutil**
- **python-watchdog**
- **python-pillow**
- **python-toml**
- **python-ijson**
- **python-numpy**
- **python-requests**

### Fonts
- **JetBrainsMono Nerd Font**
- **Noto Fonts Emoji**
- **Noto Fonts CJK**

---

## 📦 Yay (AUR) Packages

### Core
- **Matugen** – Dynamic color generation (**required**)
- **python-fabric-git**
- **fabric-cli**
- **python-setproctitle**
- **gray**

### Shell & CLI
- **Oh My Zsh** – Zsh framework
- **Powerlevel10k** – Zsh prompt theme
- **Eza** – Modern `ls` replacement

### Theming & Appearance
- **adw-gtk-theme** – GTK theme
- **Bibata Modern Ice** – Cursor theme

### Fonts
- **Geist Mono (OTF)** – Primary UI & terminal font
- **Geist Mono Nerd Font** – Icon support
- **PP Neue Machina** – Display / clock font

---

## 📝 Notes
- Run `fc-cache -fv` after installing fonts
- **PP Neue Machina** may require manual installation
- **Matugen** should be integrated with Hyprland, Waybar, GTK & Rofi


### Package Management
- **yay** – AUR helper  

> ⚠️ Without **Matugen**, colors and accents will not update dynamically.

</details>

---
<h2><sub><img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Rocket.png" alt="Rocket" width="25" height="25" /></sub> Roadmap</h2>

- [x] Hyprland
- [x] Hyprlock
- [x] Rofi
- [x] Waybar
- [x] SwayNC
- [x] Wlogout
- [x] Calendar
- [x] Clipboard Manager
- [x] Emoji Picker
- [x] Color Picker
- [ ] Customizable UI
- [ ] More polish
- [ ] Better scripts
- [ ] Additional themes
- [ ] Documentation improvements


## Special Thanks to

- **[Hyprland Community](https://github.com/hyprwm)** Thanks to the Hyprland maintainers and contributors for creating and maintaining an outstanding Wayland compositor.

- **[Wayland Contributors](https://wayland.freedesktop.org)** Appreciation to the Wayland developers and contributors for providing the foundation for modern Linux desktops.

-  **[aadritobasu](https://github.com/aadritobasu)** Huge thanks for Akaris Jsonc I’ve yanked parts of it.
