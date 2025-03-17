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
		shortdesc = "&Remove current file from playlist and filesystem";
		description = [[
<h1>vlc-delete</h1>"
When you're playing a file, use VLC Delete to
delete the current file from your playlist <b>and filesystem</b> with one click.<br />
This extension has been tested on GNU Linux with VLC 2.x and 3.x.<br />
The author is not responsible for damage caused by this extension.
		]];
	}
end

function file_exists(file)
	retval, err = os.execute("if exist \"" .. file .. "\" (exit 0) else (exit 1)")
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

function remove_from_playlist()
	local id = vlc.playlist.current()
	vlc.playlist.next()
	sleep(1) -- wait for current item change
	vlc.playlist.delete(id)
end

function command_exists(command)
	retval, err = os.execute(command)
	return retval ~= nil
end

function current_uri_and_os()
	local item = (vlc.player or vlc.input).item()
	local uri = item:uri()
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

function activate()
	local uri, is_posix = current_uri_and_os()
	vlc.msg.info("[vlc-delete] removing: " .. uri)
	remove_from_playlist()

	if is_posix then
		local trash_put_exists = command_exists("trash-put --version > /dev/null")
		local rm_exists = command_exists("rm --version > /dev/null")

		if trash_put_exists then
			vlc.msg.dbg("[vlc-delete] removing using trash-put")
			uri = string.gsub(uri, "\"", "\\\"")
			retval, err = os.execute("trash-put \"" .. uri .. "\"")
		elseif rm_exists then
			vlc.msg.dbg("[vlc-delete] removing using rm")
			uri = string.gsub(uri, "\"", "\\\"")
			retval, err = os.execute("rm \"" .. uri .. "\"")
		else
			vlc.msg.dbg("[vlc-delete] removing using os.remove")
			retval, err = os.remove(uri)
		end
	else
		vlc.msg.dbg("[vlc-delete] removing using del")
		retval, err = windows_delete(uri, 3, 1)
	end

	if retval == nil then
		vlc.msg.err("[vlc-delete] error: " .. (err or "nil"))
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
