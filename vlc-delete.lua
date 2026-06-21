--[[
	Copyright 2015-2025 surrim & contributors

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]--

config = {
	ask_confirmation = false,
	use_trash = false,
	show_floating_button = false
}

function get_config_path()
	local is_posix = (package.config:sub(1, 1) == "/")
	local base_path = ""
	if is_posix then
		base_path = os.getenv("HOME") or os.getenv("USER") or "."
		return base_path .. "/.vlc-delete-config.json"
	else
		base_path = os.getenv("APPDATA") or os.getenv("USERPROFILE") or "."
		return base_path .. "\\vlc\\vlc-delete-config.json"
	end
end

function load_config()
	local path = get_config_path()
	local status, f = pcall(io.open, path, "r")
	if status and f then
		local content = f:read("*all")
		f:close()
		if content then
			config.ask_confirmation = content:find('"ask_confirmation": true') ~= nil
			config.use_trash = content:find('"use_trash": true') ~= nil
			config.show_floating_button = content:find('"show_floating_button": true') ~= nil
		end
	end
end

function save_config()
	local path = get_config_path()
	-- Create VLC config dir on windows if it doesn't exist
	if package.config:sub(1, 1) ~= "/" then
		local base_path = os.getenv("APPDATA") or os.getenv("USERPROFILE")
		if base_path then os.execute('mkdir "' .. base_path .. '\\vlc" >nul 2>&1') end
	end

	local status, f = pcall(io.open, path, "w")
	if status and f then
		local ask_str = config.ask_confirmation and "true" or "false"
		local trash_str = config.use_trash and "true" or "false"
		local float_str = config.show_floating_button and "true" or "false"
		f:write('{\n  "ask_confirmation": ' .. ask_str .. ',\n  "use_trash": ' .. trash_str .. ',\n  "show_floating_button": ' .. float_str .. '\n}\n')
		f:close()
	else
		vlc.msg.err("[vlc-delete] Could not save configuration to: " .. tostring(path))
	end
end

function descriptor()
	return {
		title = "VLC Delete";
		version = "0.3";
		author = "surrim";
		url = "https://github.com/surrim/vlc-delete/";
		shortdesc = "Remove current file from playlist and filesystem";
		description = [[
<h1>vlc-delete</h1>
When you're playing a file, use VLC Delete to
delete the current file from your playlist <b>and filesystem</b> with one click.<br />
Includes settings for confirmation dialogues and Native OS Trash Bin integration.
		]];
		capabilities = {"menu"}
	}
end

function file_exists(file)
	local safe_file = string.gsub(file, '"', '')
	local retval, err = os.execute('if exist "' .. safe_file .. '" (exit 0) else (exit 1)')
	return type(retval) == "number" and retval == 0
end

function sleep(seconds)
	local t_0 = os.clock()
	while os.clock() - t_0 <= seconds do end
end

function windows_delete(file, trys, pause)
	if not file_exists(file) then
		return nil, "File does not exist"
	end
	local safe_file = string.gsub(file, '"', '')
	for i = trys, 1, -1 do
		os.execute('del /q "' .. safe_file .. '"')
		if not file_exists(file) then
			return true
		end
		sleep(pause)
	end
	return nil, "Unable to delete file"
end

function windows_trash(file, trys, pause)
	if not file_exists(file) then
		return nil, "File does not exist"
	end
	for i = trys, 1, -1 do
		local safe_file = string.gsub(file, "'", "''")
		local cmd = "powershell.exe -NoProfile -WindowStyle Hidden -Command \"Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('" .. safe_file .. "', 'OnlyErrorDialogs', 'SendToRecycleBin')\""
		os.execute(cmd)
		if not file_exists(file) then
			return true
		end
		sleep(pause)
	end
	return nil, "Unable to send file to Recycle Bin"
end

function remove_from_playlist()
	local id = vlc.playlist.current()
	vlc.playlist.next()
	-- Sleep only 0.2s instead of 1s to prevent VLC UI hanging
	sleep(0.2)
	vlc.playlist.delete(id)
end

function command_exists(command)
	local retval, err = os.execute(command)
	if retval == 32512 or retval == 127 or retval == 1 then
		return false
	end
	return retval ~= nil
end

function current_uri_and_os()
	local input = vlc.player or vlc.input
	if not input then return nil, nil end
	local item = input.item()
	if not item then return nil, nil end
	local uri = item:uri()
	if not uri then return nil, nil end

	local is_posix = (package.config:sub(1, 1) == "/")
	if uri:find("^file:///") ~= nil then
		uri = string.gsub(uri, "^file:///", "")
		uri = vlc.strings.decode_uri(uri)
		if is_posix then
			uri = "/" .. uri
		else
			uri = string.gsub(uri, "/", "\\")
		end
	end
	return uri, is_posix
end

-- Global dialog variables
dlg = nil
settings_dlg = nil
floating_dlg = nil
d = nil

-- Global Checkbox elements
chk_ask = nil
chk_trash = nil
chk_float = nil

function menu()
	return {"Delete Current File", "Show Floating Button", "Settings"}
end

function trigger_menu(id)
	load_config()
	if id == 1 then
		activate()
	elseif id == 2 then
		config.show_floating_button = true
		save_config()
		show_floating_button_dialog()
	elseif id == 3 then
		show_settings_dialog()
	end
end

function activate()
	load_config()
	local uri, is_posix = current_uri_and_os()
	
	if not uri then
		-- No video is currently playing. Open the Settings Dialog as a fallback.
		show_settings_dialog()
	else
		-- Video is playing. Proceed with deletion workflow.
		if config.ask_confirmation then
			show_confirmation_dialog()
		else
			click_remove()
		end
	end
end

function show_floating_button_dialog()
	if dlg then dlg:delete(); dlg = nil end
	if settings_dlg then settings_dlg:delete(); settings_dlg = nil end
	if d then d:delete(); d = nil end

	if floating_dlg then
		return
	end
	floating_dlg = vlc.dialog("VLC Delete")
	floating_dlg:add_button("🗑️ Delete Current File", activate, 1, 1, 1, 1)
	floating_dlg:show()
end

function show_confirmation_dialog()
	if floating_dlg then floating_dlg:delete(); floating_dlg = nil end
	if settings_dlg then settings_dlg:delete(); settings_dlg = nil end

	local uri, is_posix = current_uri_and_os()
	if not uri then
		vlc.msg.err("[vlc-delete] error: Could not get current file")
		return
	end

	dlg = vlc.dialog("VLC Delete - Confirmation")
	dlg:add_label("Are you sure you want to delete this file from disk?", 1, 1, 2, 1)
	dlg:add_label("File: " .. uri, 1, 2, 2, 1)
	dlg:add_button("Remove", click_remove, 1, 3, 1, 1)
	dlg:add_button("Cancel", click_cancel, 2, 3, 1, 1)
	dlg:show()
end

function show_settings_dialog()
	if floating_dlg then floating_dlg:delete(); floating_dlg = nil end
	if dlg then dlg:delete(); dlg = nil end

	if settings_dlg then
		settings_dlg:delete()
		settings_dlg = nil
	end
	settings_dlg = vlc.dialog("VLC Delete - Settings")
	chk_ask = settings_dlg:add_check_box("Ask for confirmation before deleting", config.ask_confirmation, 1, 1, 2, 1)
	chk_trash = settings_dlg:add_check_box("Send to Trash/Recycle Bin (instead of permanent delete)", config.use_trash, 1, 2, 2, 1)
	chk_float = settings_dlg:add_check_box("Keep a floating 'Delete' button on screen", config.show_floating_button, 1, 3, 2, 1)
	settings_dlg:add_button("Save", click_save_settings, 1, 4, 1, 1)
	settings_dlg:add_button("Cancel", click_cancel_settings, 2, 4, 1, 1)
	settings_dlg:show()
end

function click_save_settings()
	if chk_ask then config.ask_confirmation = chk_ask:get_checked() end
	if chk_trash then config.use_trash = chk_trash:get_checked() end
	if chk_float then config.show_floating_button = chk_float:get_checked() end
	save_config()
	if settings_dlg then
		settings_dlg:delete()
		settings_dlg = nil
	end
	
	if config.show_floating_button then
		show_floating_button_dialog()
	else
		deactivate()
	end
end

function click_cancel_settings()
	if settings_dlg then
		settings_dlg:delete()
		settings_dlg = nil
	end
	
	if config.show_floating_button then
		show_floating_button_dialog()
	else
		deactivate()
	end
end

function click_remove()
	if dlg then dlg:delete(); dlg = nil end
	if floating_dlg then floating_dlg:delete(); floating_dlg = nil end
	if settings_dlg then settings_dlg:delete(); settings_dlg = nil end

	local uri, is_posix = current_uri_and_os()
	if not uri then
		vlc.msg.err("[vlc-delete] error: Could not get current file")
		deactivate()
		return
	end
	
	vlc.msg.info("[vlc-delete] removing: " .. uri)
	remove_from_playlist()

	local retval = nil
	local err = nil

	if is_posix then
		if config.use_trash then
			local trash_put_exists = command_exists("trash-put --version > /dev/null 2>&1")
			local gio_exists = command_exists("gio help trash > /dev/null 2>&1")
			local is_mac = command_exists("osascript -e 'return 1' > /dev/null 2>&1")

			vlc.msg.dbg("[vlc-delete] removing using trash")
			
			if is_mac then
				-- Escape double quotes for AppleScript string
				local safe_uri_mac = string.gsub(uri, "\"", "\\\"")
				retval, err = os.execute("osascript -e 'tell application \"Finder\" to delete POSIX file \"" .. safe_uri_mac .. "\"'")
			else
				-- Secure shell escaping for Linux: Replace single quote with '\'' and wrap in single quotes
				local safe_uri = "'" .. string.gsub(uri, "'", "'\\''") .. "'"
				if gio_exists then
					retval, err = os.execute("gio trash " .. safe_uri)
				elseif trash_put_exists then
					retval, err = os.execute("trash-put " .. safe_uri)
				else
					vlc.msg.err("[vlc-delete] No trash command found, falling back to rm")
					retval, err = os.execute("rm " .. safe_uri)
				end
			end
		else
			local rm_exists = command_exists("rm --version > /dev/null 2>&1")
			if rm_exists then
				vlc.msg.dbg("[vlc-delete] removing using rm")
				-- Secure shell escaping for Linux
				local safe_uri = "'" .. string.gsub(uri, "'", "'\\''") .. "'"
				retval, err = os.execute("rm " .. safe_uri)
			else
				vlc.msg.dbg("[vlc-delete] removing using os.remove")
				retval, err = os.remove(uri)
			end
		end
	else
		-- Windows environments
		if config.use_trash then
			vlc.msg.dbg("[vlc-delete] removing using Recycle Bin via PowerShell")
			retval, err = windows_trash(uri, 3, 1)
		else
			vlc.msg.dbg("[vlc-delete] removing using del")
			retval, err = windows_delete(uri, 3, 1)
		end
	end

	if retval == nil then
		vlc.msg.err("[vlc-delete] error: " .. (err or "Unknown error occurred"))
		d = vlc.dialog("VLC Delete Error")
		d:add_label("Could not remove the following file:", 1, 1, 1, 1)
		d:add_label(uri, 1, 2, 1, 1)
		d:add_label("Error: " .. (err or "nil"), 1, 3, 1, 1)
		d:add_button("OK", click_ok, 1, 4, 1, 1)
		d:show()
	else
		if config.show_floating_button then
			show_floating_button_dialog()
		else
			deactivate()
		end
	end
end

function click_cancel()
	if dlg then
		dlg:delete()
		dlg = nil
	end
	if config.show_floating_button then
		show_floating_button_dialog()
	else
		deactivate()
	end
end

function click_ok()
	if d then
		d:delete()
		d = nil
	end
	if config.show_floating_button then
		show_floating_button_dialog()
	else
		deactivate()
	end
end

function deactivate()
	if dlg then
		dlg:delete()
		dlg = nil
	end
	if settings_dlg then
		settings_dlg:delete()
		settings_dlg = nil
	end
	if d then
		d:delete()
		d = nil
	end
	if floating_dlg then
		floating_dlg:delete()
		floating_dlg = nil
	end
	vlc.deactivate()
end

function close()
	deactivate()
end

function meta_changed()
end
