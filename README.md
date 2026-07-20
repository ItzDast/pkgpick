# pkgpick

[English](README.md) | [Русский](README_RU.md)

A TUI package manager for Arch Linux, built on fzf.

pkgpick lets you search, install, update, remove, and inspect packages from official repos, AUR, Flatpak, npm, pip, cargo, go, and pipx — all from one interface.

## Features

- Search and install packages from official repos, AUR, and Flatpak
- Manage installed packages per-source, or all at once with a combined view
- Full source-wide update button (e.g. "update everything from AUR")
- Optional support for npm, pip, cargo, go, and pipx (toggle in Settings, or use `--full` for one run)
- Built-in Cleanup menu: package caches, orphaned packages, AUR helper cache, unused Flatpak runtimes
- Sort/filter installed lists live by name, size, install date, explicit/dependency
- Vim-style navigation (`h`/`j`/`k`/`l`) in every search-free menu, alongside arrow keys
- Pressing Enter on a yes/no confirmation defaults to "yes"
- English and Russian interface, switchable anytime from Settings
- Lightweight, dependency-light, entirely terminal-based

## Installation

```bash
yay -S pkgpick
```

or

```bash
paru -S pkgpick
```

## Usage

```bash
pkgpick
```

Select a package and choose the required action.

## Requirements

- Arch Linux
- bash
- fzf
- pacman

Optional:

- yay or paru — AUR support
- flatpak — Flatpak apps/runtimes
- npm, pip, cargo, go, pipx — shown in the source menu only when installed

## Interface Languages

pkgpick supports:

- English
- Russian

On first run you're prompted to pick a language; it's saved and can be changed anytime from the Settings menu.

## License

GPL-3.0-or-later
