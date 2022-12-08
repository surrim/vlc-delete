--[[
	Copyright 2015-2022 surrim

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

function fileExists(file)
	return io.popen("if exist " .. file .. " (echo 1)") : read "*l" == "1"
end

function sleep(seconds)
	local t0 = os.clock()
	local tOriginal = t0
	while os.clock() - t0 <= seconds and os.clock() >= tOriginal do end
end

function windowsDelete(file, trys, pause)
	if not fileExists("\"" .. file .. "\"") then return nil, "File does not exist" end
	for i = trys, 1, -1
	do
		retval, err = os.remove(file)
		--retval, err = os.execute("del " .. file )
		if retval == true then
			return true
		end
		sleep(pause)
	end
	return {nil, "Unable to delete file"}
end

function removeItem()
	local id = vlc.playlist.current()
	vlc.playlist.delete(id)
	vlc.playlist.gotoitem(id + 1)
	vlc.deactivate()
end

function activate()
	local item = vlc.input.item()
	local uri = item:uri()
	uri = string.gsub(uri, "^file:///", "")
	uri = vlc.strings.decode_uri(uri)
	vlc.msg.info("[vlc-delete] removing: " .. uri)

	if (package.config:sub(1, 1) == "/") then -- not windows
		retval, err = os.execute("trash-put --help > /dev/null")
		if (retval ~= nil) then
			uri = "/" .. uri
			retval, err = os.execute("trash-put \"" .. uri .. "\"")
		else
			retval, err = os.execute("rm --help > /dev/null")
			if (retval ~= nil) then
				uri = "/" .. uri
				retval, err = os.execute("rm \"" .. uri .. "\"")
			end
		end
		if (retval ~= nil) then removeItem() end
	else -- windows
		removeItem() -- remove from playlist first so the file isnt locked by vlc
		uri = string.gsub(uri, "/", "\\")
		retval, err = windowsDelete(uri, 3, 1)
	end

	if (retval == nil) then
		vlc.msg.info("[vlc-delete] error: " .. err)
		d = vlc.dialog("VLC Delete")
		d:add_label("Could not remove \"" .. uri .. "\"", 1, 1, 1, 1)
		d:add_label(err, 1, 2, 1, 1)
		d:add_button("OK", click_ok, 1, 3, 1, 1)
		d:show()
	end
end

function click_ok()
	d:delete()
	vlc.deactivate()
end

function deactivate()
	vlc.deactivate()
end

function close()
	deactivate()
end

function meta_changed()
end
