-- Session handling routines - written for acf
-- Copyright (C) 2007 N. Angelacos - GPL2 License
-- Copyright (C) 2023 T. Bonnin - Compat Lua 5.4 - GPL2 License

--[[ Note that in this library, we use empty (0 byte) files
-- everwhere we can, as they only take up dir entries, not inodes
-- as the tmpfs blocksize is 4K, and under denial of service
-- attacks hundreds or thousands of events can come in each
-- second, we could end up in a disk full condition if we did
-- not take this precaution.
-- ]]--

local mymodule = {}

posix = require("posix")

minutes_expired_events=30
minutes_count_events=30
limit_count_events=10

cached_content=nil

local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"

-- Return a sessionid of at least size bits length
mymodule.random_hash = function (size)
	local file = io.open("/dev/urandom")
	local str = ""
	if file == nil then return nil end
	while (size > 0 ) do
		local offset = (string.byte(file:read(1)) % 64) + 1
		str = str .. string.sub (b64, offset, offset)
		size = size - 6
	end
	return str
end

-- FIXME: only hashes ipv4
mymodule.hash_ip_addr = function (ip)
	local str = ""
	for i in string.gmatch(ip or "", "%d+") do
		str = str .. string.format("%02x", i )
	end
	return str
end

mymodule.ip_addr_from_hash = function (hash)
	local str = ""
	for i in string.gmatch(hash or "", "..") do
		str = str .. string.format("%d", "0x" .. i) .. "."
	end
	return string.sub(str, 1, string.len(str)-1)
end

--[[
	These functions serialize a table, including nested tables.
	The code based on code in PiL 2nd edition p113
]]--
local function basicSerialize (o)
	if type(o) == "number" then
		return tostring(o)
	else
		return string.format("%q", o)
	end
end

mymodule.serialize = function(name, value, saved, output )
	local need_to_concat = (output == nil)
	output = output or {}
	saved = saved or {}
	local str = name .. " = "
	if type(value) == "number" or type(value) == "string" then
		table.insert(output, str .. basicSerialize (value))
	elseif type(value) == "table" then
		if saved[value] then
			table.insert(output, str .. saved[value])
		else
			saved[value] = name
			table.insert(output, str .. "{}")
			for k,v in pairs(value) do
				local fieldname = string.format("%s[%s]", name, basicSerialize(k))
				mymodule.serialize (fieldname, v, saved, output)
			end
		end
	elseif type(value) == "boolean" then
		table.insert(output, str .. tostring(value))
	else
		table.insert(output, str .. "nil")	 -- cannot save other types, so skip them
	end
	if need_to_concat then
		table.sort(output)
		return table.concat(output, "\n")
	end
	return
end

-- Save the session (unless all it contains is the id)
-- return true or false for success
mymodule.save_session = function( sessionpath, sessiontable)
	if nil == sessiontable or nil == sessiontable.id then return false end

	-- clear the id key, don't need to store that
	local id = sessiontable.id
	sessiontable.id = nil

	-- If the table only has an "id" field, then don't save it
	if #sessiontable then
		local output = {}
		output[#output+1] = "-- This is an ACF session table."
		output[#output+1] = "local " .. mymodule.serialize("s", sessiontable)
		output[#output+1] = "return s"
		local content = table.concat(output, "\n") .. "\n"

		-- want to avoid writing unless changed, because opening for write
		-- prevents simultaneous opening for read
		if content ~= cached_content then
			local file = io.open(sessionpath .. "/session." .. id , "w")
			if file == nil then
				sessiontable.id=id
				return false
			end
			
			file:write(content)
			file:close()
		end
	end

	sessiontable.id=id
	return true
end

-- Loads a session
-- Returns a timestamp (when the session data was saved) and the session table.
-- Insert the session into the "id" field
mymodule.load_session = function ( sessionpath, session )
	if type(session) ~= "string" then return nil, {} end
	local s = {}
	-- session can only have b64 characters in it
	session = string.gsub ( session or "", "[^" .. b64 .. "]", "")
	if #session == 0 then
		return nil, {}
	end
	local spath = sessionpath .. "/session." .. session
	local ts = posix.stat(spath, "ctime")
	if (ts) then
		-- this loop is here because can't read file here if another process is writing it above
		-- and if this fails, it effectively logs the user off (writes back blank session data)
		local s
		for i=1,20 do
			local file = io.open(spath)
			if file then
				cached_content = file:read("*a")
				file:close()
				s = load(cached_content)() -- Replace 'loadstring' to 'load' for Lua >=5.3 compat
				break
			end
			sleep(10*i)
		end

		s = s or {}
		s.id = session
		return ts, s
	else
		return nil, {}
	end
end

-- Unlinks a session (deletes the session file)
-- return nil for failure, ?? for success
mymodule.unlink_session = function (sessionpath, session)
	if type(session)  ~= "string" then return nil end
	local s = string.gsub (session, "[^" .. b64 .. "]", "")
	if s ~= session then
		return nil
	end
	session = sessionpath .. "/session." .. s
	local statos = os.remove (session)
	return statos
end

-- Record an invalid logon event
-- ID would typically be an ip address or username
-- the format is lockevent.id.datetime.processid
mymodule.record_event = function( sessionpath, id_u, id_ip )
	local x = io.open (string.format ("%s/lockevent.%s.%s.%s.%s",
		 sessionpath or "/", id_u or "", mymodule.hash_ip_addr(id_ip), os.time(),
		 (posix.getpid("pid")) or "" ), "w")
	io.close(x)
end

-- List invalid logon events
-- Can specify username and/or ip address to filter
mymodule.list_events =	function (sessionpath, id_user, ipaddr, minutes)
	local list = {}
	local now = os.time()
	local minutes_ago = now - ((minutes or minutes_count_events) * 60)
	local t = {}
	--give me all lockevents then we will sort through them
	local searchfor = sessionpath .. "/lockevent.*"
	local t = posix.glob(searchfor)

	local ipaddrhash = mymodule.hash_ip_addr(ipaddr)
	for a,b in pairs(t or {}) do
		if posix.stat(b,"mtime") > minutes_ago then
			local user, ip, time, pid = string.match(b, "/lockevent%.([^.]*)%.([^.]*)%.([^.]*)%.([^.]*)$")
			if user and (not id_user or id_user == user) and (not ipaddr or ipaddrhash == ip) then
				list[#list+1] = {userid=user, ip=mymodule.ip_addr_from_hash(ip), time=time, pid=pid}
			end
		end
	end
	return list
end

-- Check how many invalid logon events
-- have happened for this id in the last n minutes
mymodule.count_events =	function (sessionpath, id_user, ipaddr, minutes, limit)
	local locked = false
	local list = mymodule.list_events(sessionpath, id_user, ipaddr, minutes)
	if #list>(tonumber(limit) or limit_count_events) then
		locked = true
	else
		locked = false
	end
	return locked
end

-- Clear events that are older than n minutes
mymodule.expired_events = function (sessionpath, minutes)
	--current os time in seconds
	local now = os.time()
	--take minutes and convert to seconds
	local minutes_ago = now - ((minutes or minutes_expired_events) * 60)
	local searchfor = sessionpath .. "/lockevent.*"
	--first do the lockevent files
	local temp = posix.glob(searchfor)
	if temp ~= nil then
 		for a,b in pairs(temp) do
			if posix.stat(b,"mtime") < minutes_ago then
			os.remove(b)
			end
 		end
	end
	--now do the session files
	searchfor = sessionpath .. "/session.*"
	local temp = posix.glob(searchfor)
	if temp ~= nil then
 		for a,b in pairs(temp) do
 			if posix.stat(b,"mtime") < minutes_ago then
			os.remove(b)
			end
 		end
	end
 	return 0
end

mymodule.delete_events = function (sessionpath, id_user, ipaddr)
	--give me all lockevents then we will sort through them
	local searchfor = sessionpath .. "/lockevent.*"
	local t = posix.glob(searchfor)

	local ipaddrhash = mymodule.hash_ip_addr(ipaddr)
	for a,b in pairs(t or {}) do
		local user, ip = string.match(b, "/lockevent%.([^.]*)%.([^.]*)%.")
		if user and (not id_user or id_user == user) and (not ipaddr or ipaddrhash == ip) then
			os.remove(b)
		end
	end
end

return mymodule
