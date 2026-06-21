# VLC Delete

When you're playing a media file, use VLC Delete to seamlessly delete the current file from your playlist **and your hard drive** with a single click.

This extension has been heavily upgraded to include a Settings UI, Native OS Trash support (so files aren't permanently destroyed by default), a floating "Always On Top" deletion button, and robust cross-platform error handling. 

It works out-of-the-box on GNU Linux, macOS, and Windows with VLC 2.x and 3.x.

## Features
- **1-Click Deletion:** Delete the currently playing file directly from the View menu.
- **Native Trash/Recycle Bin Support:** Safely moves files to your OS Trash instead of permanently deleting them (`gio trash` or `trash-put` on Linux, `osascript` on macOS, and `PowerShell` on Windows).
- **Settings UI:** Easily toggle confirmation dialogues, Trash usage, and a floating button.
- **Floating Button:** An "Always On Top" button allowing you to delete the file without opening the menu.
- **Cross-Platform:** Automatic detection and safe-escaping for Linux, Windows, and macOS paths.

---

## Installation

### Linux
1. Create the extensions folder if it doesn't exist:
   ```bash
   mkdir -p ~/.local/share/vlc/lua/extensions/
   ```
2. Copy the `vlc-delete.lua` file to that directory:
   ```bash
   cp vlc-delete.lua ~/.local/share/vlc/lua/extensions/
   ```
*(Note: If you installed VLC via Flatpak or Snap, the extensions path may differ. For Flatpak, it is usually `~/.var/app/org.videolan.VLC/data/vlc/lua/extensions/`)*

### Windows
1. Open File Explorer and navigate to:
   `%APPDATA%\vlc\lua\extensions\`
   *(If the `lua` or `extensions` folders do not exist, create them).*
2. Copy `vlc-delete.lua` into this folder.

### macOS
1. Open Finder and navigate to:
   `~/Library/Application Support/org.videolan.vlc/lua/extensions/`
   *(If the folders do not exist, create them).*
2. Copy `vlc-delete.lua` into this folder.

---

## How to Use

After installation, restart VLC or go to **Tools -> Plugins and extensions**, click the **Active Extensions** tab, and hit **Reload extensions**.

VLC Delete will now be available in the **View** menu at the top of your VLC window.

### Accessing Settings & Configuring the Extension
Due to limitations in how VLC's interface renders extension menus on certain Linux desktop environments (like XFCE), we implemented a clever fallback so you can always access your settings:

1. **Stop any currently playing video.** (Press the Stop button `⏹` in VLC).
2. Go to the **View** menu and click **VLC Delete**.
3. Because no video is playing, the **Settings window** will automatically open.

From the Settings window, you can:
- **Ask for confirmation:** If enabled, you will be prompted before a file is deleted.
- **Send to Trash/Recycle Bin:** Highly recommended. Instead of permanent deletion, files will be moved to your system's Trash folder.
- **Keep a floating 'Delete' button:** A small persistent window will stay on your screen. You can click it at any time while a video is playing to delete it instantly.

### Deleting a File
1. Play any video or audio file.
2. Go to **View -> VLC Delete**.
3. The file will be immediately stopped, removed from the playlist, and deleted from your hard drive (or moved to the Trash, based on your settings).

*Alternatively, if you enabled the **Floating Button** in Settings, you can simply click the floating "🗑️ Delete Current File" button while the video is playing.*

---

## Disclaimer
The author is not responsible for any accidental damage or data loss caused by this extension. It is strongly recommended to leave the "Send to Trash" setting enabled to prevent accidental permanent deletion.
