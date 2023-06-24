-- ACF Authenticator - does validation and loads sub-authenticator to read/write database
-- We store the logon info in the passwd table, "" field.  It looks like
--	password:username:ROLE1[,ROLE2...]
local mymodule = {}

modelfunctions = require("modelfunctions")
format = require("acf.format")
md5 = require("md5")
posix = require("posix")
session = require("session")

-- This is the sub-authenticator
local auth = {}

-- List all fields, combining all subauths
auth.list_fields = function(self, tabl)
	if not auth.subauths then
		return nil
	end
	local fields = {}
	local revfields = {}
	for i,sub in ipairs(auth.subauths) do
		local subf = sub.list_fields(self, tabl)
		for j,f in ipairs(subf or {}) do
			if not revfields[f] then
				fields[#fields+1] = f
				revfields[f] = #fields
			end
		end
	end
	return fields
end

-- Read all entries from field, combining all subauths (first entry for id takes precedence)
auth.read_field = function(self, tabl, field)
	if not auth.subauths then
		return nil
	end
	local entries = {}
	local reventries = {}
	for i,sub in ipairs(auth.subauths) do
		local f = sub.read_field(self, tabl, field)
		for j,a in ipairs(f or {}) do
			if not reventries[a.id] then
				entries[#entries+1] = a
				reventries[a.id] = i
			end
		end
	end
	return entries
end

-- Delete all entries in all subauths for specified field
auth.delete_field = function(self, tabl, field)
	if not auth.subauths then
		return nil
	end
	for i,sub in ipairs(auth.subauths) do
		sub.delete_field(self, tabl, field)
	end
	return false
end

-- Should we write to the first subauth that allows writes or to subauth where entry already exists?
-- Chose to write to first subauth that allows writes because overrides all others
auth.write_entry = function(self, tabl, field, id, entry)
	if not auth.subauths then
		return nil
	end
	for i,sub in ipairs(auth.subauths) do
		if sub.write_entry(self, tabl, field, id, entry) then
			return true
		end
	end
	return false
end

-- Return the details from the first match from one of the subauths
auth.read_entry = function(self, tabl, field, id)
	if not auth.subauths then
		return nil
	end
	for i,sub in ipairs(auth.subauths) do
		local e = sub.read_entry(self, tabl, field, id)
		if e then
			return e
		end
	end
	return nil
end

-- Delete the entry from all subauths
auth.delete_entry = function (self, tabl, field, id)
	if not auth.subauths then
		return nil
	end
	for i,sub in ipairs(auth.subauths) do
		sub.delete_entry(self, tabl, field, id)
	end
	return true
end

-- Publicly define the pre-defined tables
mymodule.usertable = "passwd"
mymodule.roletable = "roles"

-- This will hold the auth structure from the database
local authstruct = {}
local complete = false

local parse_entry = function(id, entry)
	local a
	if id and id ~= "" and entry and entry ~= "" then
		local fields = {}
		for x in string.gmatch(entry or "", "([^:]*):?") do
			fields[#fields + 1] = x
		end
		a = {}
		a.userid = id
		a.password = fields[1] or ""
		a.username = fields[2] or ""
		a.roles = fields[3] or ""
		a.skin = fields[4] or ""
		a.home = fields[5] or ""
		authstruct[id] = a
	end
	return a
end

local load_database = function(self)
	if not complete then
		local authtable = auth.read_field(self, mymodule.usertable, "") or {}
		authstruct = {}
		for i,value in ipairs(authtable) do
			parse_entry(value.id, value.entry)
		end
		complete = true
	end
end

local get_id = function(self, userid)
	if not authstruct[userid] then
		parse_entry(userid, auth.read_entry(self, mymodule.usertable, "", userid))
	end
	return authstruct[userid]
end

-- verify a plaintextword against a hash
-- returns:
--	true if password matches or
--	false if password does not match
local verify_password = function(plaintext, pwhash)
	--[[
	from man crypt(3):

	If  salt is a character string starting with the characters "$id$" fol-
	lowed by a string terminated by "$":

              $id$salt$encrypted

	then instead of using the DES machine,  id  identifies  the  encryption
	method  used  and  this  then  determines  how the rest of the password
	string is interpreted.  The following values of id are supported:

              ID  | Method
              ---------------------------------------------------------
              1   | MD5
              2a  | Blowfish (not in mainline glibc; added in some
                  | Linux distributions)
              5   | SHA-256 (since glibc 2.7)
              6   | SHA-512 (since glibc 2.7)
	]]--
	local algo_salt, hash = string.match(pwhash, "^(%$%d%$[a-zA-Z0-9./]+%$)(.*)")
	if algo_salt ~= nil and hash ~= nil then
		return (pwhash == posix.crypt(plaintext, algo_salt))
	end
	-- fall back to old style md5 checksum
	return (pwhash == md5.sumhexa(plaintext))
end

local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789./"

local mksalt = function()
	local file = io.open("/dev/urandom")
	local str = ""
	if file == nil then return nil end
	for i = 1,16 do
		local offset = (string.byte(file:read(1)) % 64) + 1
		str = str .. string.sub (b64, offset, offset)
	end
	return "$6$"..str.."$"
end

--- public methods

mymodule.get_subauth = function(self)
	if not auth.subauths then
		auth.subauths = {}
		if self and self.conf and self.conf.authenticator and self.conf.authenticator ~= "" then
			for a in string.gmatch(self.conf.authenticator, "[^,]+") do
				auth.subauths[#auth.subauths+1] = require(string.gsub(a, "%.lua$", ""))
				auth.subauths[#auth.subauths].name = a
			end
		else
			auth.subauths[1] = require("authenticator-plaintext")
		end
	end
	return auth
end

-- This function returns true or false, and
-- if false:  the reason for failure
mymodule.authenticate = function(self, userid, password)
	auth = mymodule.get_subauth(self)
	local errtxt

	if not userid or not password then
		errtxt = "Invalid parameter"
	else
		local id = get_id(self, userid)

		if not id then
			errtxt = "Userid not found"
		elseif not verify_password(password, id.password) then
			errtxt = "Invalid password"
		end
	end

	return (errtxt == nil), errtxt
end

-- This function returns the username, roles, ...
mymodule.get_userinfo = function(self, userid)
	auth = mymodule.get_subauth(self)
	local id = get_id(self, userid)
	if id then
		-- Make a copy so roles don't get changed in the authstruct
		local result = {}
		for n,v in pairs(id) do
			result[n]=v
		end
		local tmp = {}
		for x in string.gmatch(id.roles or "", "([^,]+),?") do
			tmp[#tmp + 1] = x
		end
		result.roles = tmp
		return result
	end
	return nil
end

mymodule.write_userinfo = function(self, userinfo)
	auth = mymodule.get_subauth(self)
	if not userinfo or not userinfo.userid or userinfo.userid == "" then
		return false
	end
	id = get_id(self, userinfo.userid) or {}
	-- Username, password, roles, skin, home are allowed to not exist, just leave the same
	id.userid = userinfo.userid
	if userinfo.username then id.username = userinfo.username end
	if userinfo.password then id.password = posix.crypt(userinfo.password, mksalt()) end
	if userinfo.roles then id.roles = table.concat(userinfo.roles, ",") end
	if userinfo.skin then id.skin = userinfo.skin end
	if userinfo.home then id.home = userinfo.home end

	local success = auth.write_entry(self, mymodule.usertable, "", id.userid, (id.password or "")..":"..(id.username or "")..":"..(id.roles or "")..":"..(id.skin or "")..":"..(id.home or ""))
	authstruct[userinfo.userid] = nil
	get_id(self, id.userid)

	if success and self.sessiondata and self.sessiondata.userinfo and self.sessiondata.userinfo.userid == id.userid then
		self.sessiondata.userinfo = {}
		for name,value in pairs(id) do
			if name == "roles" then
				if value == "" then
					value = "GUEST"
				else
					value = value..",GUEST"
				end
				self.sessiondata.userinfo.roles = format.string_to_table(value, "%s*,%s*")
			else
				self.sessiondata.userinfo[name] = value
			end
		end
	end

	return success
end

mymodule.list_users = function (self)
	auth = mymodule.get_subauth(self)
	load_database(self)
	local output = {}
	for k in pairs(authstruct) do
		table.insert(output,k)
	end
	return output
end

mymodule.delete_user = function (self, userid)
	auth = mymodule.get_subauth(self)
	authstruct[userid] = nil
	return auth.delete_entry(self, mymodule.usertable, "", userid)
end

return mymodule
