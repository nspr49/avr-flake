# AVR course setup on macOS

1. Install [Nix](https://nix.dev/install-nix) and [VS Code](https://code.visualstudio.com/). Open a new Terminal window after installing Nix.
2. Double-click the course ZIP in Finder to extract it. In Terminal, `cd` to the extracted folder containing `flake.nix`, then make the workspace scripts executable:

   ```sh
   chmod +x .mpt/scripts/*
   ```
3. In VS Code, choose **File → Open Folder**, open that extracted folder, and trust the workspace. When prompted to install the [recommended workspace extensions](README.md#install-editor-extensions), click **Install**. Press **⌘⇧B** to build. The first build downloads the pinned tools.
4. Connect the Curiosity Nano with a USB data cable and approve the accessory if prompted. In the Command Palette, choose **Tasks: Run Task → Build and Flash Curiosity Nano**. This replaces the firmware on the board.
