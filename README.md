# pkgpick

[English](README.md) | [Русский](README_RU.md)

A simple TUI package picker for Arch Linux.

pkgpick is an fzf-based interface for searching and installing packages from official repositories, AUR, and installed packages.

## Features

- Search packages using fzf
- Install packages from official repositories
- Install packages from AUR
- Manage installed packages
- English and Russian interface support
- Lightweight and terminal-based

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

- yay
- paru

## Interface Languages

pkgpick supports:

- English
- Russian

The interface language is detected automatically from the system locale.

## License

GPL-3.0-or-later
