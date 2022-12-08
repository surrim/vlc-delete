# Install

## Windows
Copy `vlc-delete.lua` to `C:\Program Files\VideoLAN\VLC\lua\extensions\` and restart the VLC Media Player.

## Linux
Copy the `vlc-delete.lua` file to `~/.local/share/vlc/lua/extensions/` and restart the VLC Media Player.

### Installation script

```bash
mkdir -p ~/.local/share/vlc/lua/extensions/
wget https://raw.githubusercontent.com/surrim/vlc-delete/master/vlc-delete.lua -O ~/.local/share/vlc/lua/extensions/vlc-delete.lua
```

Note: If [trash-cli](https://pypi.org/project/trash-cli/) is installed videos will be moved to the recycle bin instead of removing them directly.

# Usage

When playing a video you can click on `View` → `Remove current file from playlist and disk`. Then the video will be removed and the next one is played.

# Known bugs and issues

- There is no *fixed* shortcut key; it depends on the menu language.  
  For instance in English: Press and hold `Alt`  to activate the hotkey navigation, then press `i` (`Vi̲ew`), then `r` (`R̲emove current file from playlist and disk`). I haven't found a solution to implement a fixed key; probably it's not supported by the VLC Media Player.  
  ![Hotkeys animation](https://raw.githubusercontent.com/surrim/vlc-delete/master/hotkeys.webp)
- Windows: UNC paths like `\SERVER\Share\File.mp4` are not working.  
  As a workaround, you could use `net use P: "\uncpath"` in the Windows terminal and open the file with a regular path.
  Thanks for contributing [Taomyn](https://github.com/Taomyn) and [freeload101](https://github.com/freeload101)
- Windows: Video can't be deleted if the file name contains emojis.  
  Thanks for contributing [Jonas1312](https://github.com/Jonas1312)

If you create a new issue please include your VLC Version number and operating system. Otherwise it's hard to reproduce.  
The biggest help would be to contribute some Lua Code.

