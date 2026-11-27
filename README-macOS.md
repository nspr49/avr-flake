# AVR course setup on macOS

## Prerequisites

- [VS Code](https://code.visualstudio.com/)
- [Nix](https://nix.dev/install-nix). Open a new Terminal window after installing it.

## Setup

1. Double-click the course ZIP in Finder to extract it. In Terminal, `cd` to the extracted folder containing `flake.nix`, then make the workspace scripts executable:

   ```sh
   chmod +x .mpt/scripts/*
   ```
2. In VS Code, choose **File → Open Folder**, open that extracted folder, and trust the workspace. When prompted to install the [recommended workspace extensions](README.md#install-editor-extensions), click **Install**. Press **⌘⇧B** to build. The first build downloads the pinned tools.
3. Connect the Curiosity Nano with a USB data cable and approve the accessory if prompted. In the Command Palette, choose **Tasks: Run Task → Build and Flash Curiosity Nano**. This replaces the firmware on the board.
