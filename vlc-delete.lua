--[[
	Copyright 2015-2023 surrim

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

function descriptor()
	return {
		title = "VLC Delete";
		version = "0.1";
		author = "surrim";
		url = "https://github.com/surrim/vlc-delete/";
		shortdesc = "&Remove current file from playlist and disk";
		description = [[
<h1>vlc-delete</h1>"
When you're playing a file, use VLC Delete to
delete the current file from your playlist and <b>disk</b> with one click.<br />
This extension has been tested on GNU Linux with VLC 2.x and 3.x.<br />
The author is not responsible for damage caused by this extension.
		]];
	}
end

function file_exists(file)
	retval, err = os.execute("if exist \"" .. file .. "\" @(call)")
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
	for i = trys, 1, -1
	do
		os.execute("del /q \"" .. file .. "\"")
		if not file_exists(file) then
			return true
		end
		sleep(pause)
	end
	return nil, "Unable to delete file"
end

function remove_from_playlist_and_hdd()
	local id = vlc.playlist.current()
	vlc.playlist.next()
	sleep(1)
	vlc.playlist.delete(id)
end

function activate()
	local item = (vlc.player or vlc.input).item()
	local uri = item:uri()
	uri = string.gsub(uri, "^file:///", "")
	uri = vlc.strings.decode_uri(uri)

	if (package.config:sub(1, 1) == "/") then -- not windows
		uri = "/" .. uri
		vlc.msg.info("[vlc-delete] removing: " .. uri)
		retval, err = os.execute("trash-put --help > /dev/null")
		if (retval ~= nil) then
			retval, err = os.execute("trash-put \"" .. uri .. "\"")
		else
			retval, err = os.execute("rm --help > /dev/null")
			if (retval ~= nil) then
				retval, err = os.execute("rm \"" .. uri .. "\"")
			end
		end
		if (retval ~= nil) then remove_from_playlist_and_hdd() end
	else -- windows
		uri = string.gsub(uri, "/", "\\")
		vlc.msg.info("[vlc-delete] removing: " .. uri)
		remove_from_playlist_and_hdd() -- remove first so the file isn't locked by VLC
		retval, err = windows_delete(uri, 3, 1)
	end

	if (retval == nil) then
		vlc.msg.info("[vlc-delete] error: " .. err)
		d = vlc.dialog("VLC Delete")
		d:add_label("Could not remove \"" .. uri .. "\"", 1, 1, 1, 1)
		d:add_label(err, 1, 2, 1, 1)
		d:add_button("OK", click_ok, 1, 3, 1, 1)
		d:show()
	else
		deactivate()
	end
end

function click_ok()
	d:delete()
	deactivate()
end

function deactivate()
	vlc.deactivate()
end

function close()
	deactivate()
end

function meta_changed()
end
