![](preview.png)

# Dotfiles

Dotfiles for a simple Arch Linux Hyprland setup.

**Applications**

- **Web Browser:** `firefox`
- **Terminal Emulator:** `kitty`
- **PulseAudio Volume Control:** `pavucontrol`
- **NetworkManager Connection Editor:** `nm-connection-editor`

**User Interface**

- **Application Launcher:** `rofi-wayland`
- **Screen Lock:** `hyprlock`
- **Status Bar:** `waybar`
- **Wallpaper Utility:** `hyprpaper`

**Utilities**

- **Idle Management Daemon:** `hypridle`
- **Notification Daemon:** `mako`
- **System Information:** `fastfetch`
- **System Monitor:** `bottom`

**Appearance**

- **Cursor Theme:** `capitaine-cursors`
- **GTK Theme:** `orchis-theme`
- **Icon Theme:** `tela-circle-icon-theme-standard`

**Extras**

- **Fastfetch Logo:** From the [osu! Spring 2024 Fanart Contest](https://osu.ppy.sh/community/contests/205) by [roadcrow__](https://osu.ppy.sh/users/11752694)
- **Wallpaper:** From the [osu! Midnight Moment Art Contest](https://osu.ppy.sh/community/contests/226) by [tehfire](https://osu.ppy.sh/users/7082924)

**Optional**

- **Game:** osu!(lazer)

## Installation

1. Install a base Arch Linux system using [arch-install-script](https://github.com/CjayDoesCode/arch-install-script).

2. Download the script.
```bash
curl -o install.sh https://raw.githubusercontent.com/CjayDoesCode/dotfiles/main/install.sh
```

3. Add executable permissions.
```bash
chmod +x install.sh
```

4. Run the script.
```bash
./install.sh
```

## Installed Packages

| Package Group       | Packages                                                                                                                                                                                                                                       |
| :------------------ | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `packages`          | `bottom` `chezmoi` `fastfetch` `firefox` `grim` `helix` `imagemagick` `kitty` `libnotify` `mako` `nm-connection-editor` `pavucontrol` `rofi-wayland` `slurp` `udiskie` `uwsm` `waybar` `wl-clipboard` `xdg-desktop-portal-gtk` `xdg-user-dirs` |
| `hyprland_packages` | `hypridle` `hyprland` `hyprpaper` `hyprlock` `hyprpolkitagent` `xdg-desktop-portal-hyprland`                                                                                                                                                   |
| `font_packages`     | `inter-font` `noto-fonts` `noto-fonts-cjk` `noto-fonts-emoji` `noto-fonts-extra` `ttf-nerd-fonts-symbols` `ttf-nerd-fonts-symbols-mono` `ttf-sourcecodepro-nerd`                                                                               |
| `theme_packages`    | `capitaine-cursors` `orchis-theme` `tela-circle-icon-theme-standard`                                                                                                                                                                           |
