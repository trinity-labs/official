local mymodule = {}

authenticator = require("authenticator")
roles = require("roles")
session = require("session")

avail_roles, avail_skins, avail_homes = nil

local weak_password = function(password)
	-- If password is too short, return false
	if (#password < 4) then
		return true, "Password is too short!"
	end
	if (tonumber(password)) then
		return true, "Password can't contain only numbers!"
	end

	return false, nil
end

local validate_settings = function(settings, create)
	-- Set errtxt when encountering invalid values
	if (#settings.value.userid.value == 0) then settings.value.userid.errtxt = "You need to enter a valid userid!" end
	if string.find(settings.value.userid.value, "[^%w_]") then settings.value.userid.errtxt = "Can only contain letters, numbers, and '_'" end
	if string.find(settings.value.username.value, "%p") then settings.value.username.errtxt = "Cannot contain punctuation" end
	-- Blank password is allowed for edit, indicates to leave the same
	if (#settings.value.password.value == 0) and create then
		settings.value.password.errtxt = "Password cannot be blank!"
	elseif (settings.value.password.value ~= settings.value.password_confirm.value) then
		settings.value.password.errtxt = "You entered wrong password/confirmation"
	elseif (#settings.value.password.value ~= 0) then
		local weak_password_result, weak_password_errormessage = weak_password(settings.value.password.value)
		if (weak_password_result) then settings.value.password.errtxt = weak_password_errormessage end
	end
	-- roles will not exist for editme action
	if settings.value.roles then modelfunctions.validatemulti(settings.value.roles) end
	modelfunctions.validateselect(settings.value.skin)
	modelfunctions.validateselect(settings.value.home)

	-- Return false if any errormessages are set
	for name,value in pairs(settings.value) do
		if value.errtxt then
			return false, settings
		end
	end

	return true, settings
end

local function get_blank_user(self)
	local result = cfe({ type="group", value={}, label="User Account" })

	if not avail_roles then
		avail_roles = roles.list_all_roles(self)
		for x,role in ipairs(avail_roles) do
			if role==roles.guest_role then
				table.remove(avail_roles,x)
				break
			end
		end
	end

	-- Call into skins controller to get the list of skins
	if not avail_skins then
		avail_skins = {""}
		local contrl = self:new("acf-util/skins")
		skins = contrl.model.get_update(contrl)
		contrl:destroy()
		for i,s in ipairs(skins.value.skin.option) do
			avail_skins[#avail_skins + 1] = s.value or s
		end
	end

	-- Call into roles library to get the list of home actions
	if not avail_homes then
		avail_homes = {""}
		local tmp1, tmp2 = roles.get_all_permissions(self)
	        table.sort(tmp2)
		for i,h in ipairs(tmp2) do
			if h ~= "/acf-util/logon/logoff" and h ~= "/acf-util/logon/logon" then
				avail_homes[#avail_homes+1] = h
			end
		end
	end

	result.value.userid = cfe({ value="", label="User id", seq=1 })
	result.value.username = cfe({ value="", label="Real name", seq=2 })
	result.value.password = cfe({ type="password", value="", label="Password", seq=4 })
	result.value.password_confirm = cfe({ type="password", value="", label="Password (confirm)", seq=5 })
	result.value.roles = cfe({ type="multi", value={}, label="Roles", option=avail_roles or {}, seq=3 })
	result.value.skin = cfe({ type="select", value="", label="Skin", option=avail_skins or {""}, seq=7 })
	result.value.home = cfe({ type="select", value="", label="Home", option=avail_homes or {""}, seq=6 })
	result.value.locked = cfe({ type="boolean", value=false, label="Locked", readonly=true, seq=8 })

	return result
end

local function get_user(self, userid)
	local result = get_blank_user(self)
	result.value.userid.key = true
	result.value.userid.value = userid or ""

	if result.value.userid.value ~= "" then
		result.value.userid.readonly = true
		local userinfo = authenticator.get_userinfo(self, result.value.userid.value)
		if not userinfo then
			result.value.userid.errtxt = "User does not exist"
			userinfo = {}
		else
			for n,v in pairs(userinfo) do
				if result.value[n] and n ~= "password" then result.value[n].value = v end
			end
		end
		result.value.locked.value = session.count_events(self.conf.sessiondir, result.value.userid.value)
	end

	return result
end

function mymodule.create_user(self, settings, submit)
	return mymodule.update_user(self, settings, submit, true)
end

function mymodule.update_user(self, settings, submit, create)
	local success, settings = validate_settings(settings, create)

	if success then
		local userinfo = authenticator.get_userinfo(self, settings.value.userid.value)
		if userinfo and create then
			settings.value.userid.errtxt = "This userid already exists!"
			success = false
		elseif not userinfo and not create then
			settings.value.userid.errtxt = "This userid does not exist!"
			success = false
		end
	end

	if success then
		local userinfo = {}
		for name,val in pairs(settings.value) do
			-- If password is blank, don't set it
			if name == "password" and val.value == "" then
			else
				userinfo[name] = val.value
			end
		end
		success = authenticator.write_userinfo(self, userinfo)
	end

	if not success then
		if create then
			settings.errtxt = "Failed to create new user"
		else
			settings.errtxt = "Failed to save settings"
		end
	end

	return settings
end

function mymodule.read_user(self, clientdata)
	-- create a temp result so handle_clientdata only handles userid
	local tmpresult = cfe({type="group", value={userid=cfe()} })
	self.handle_clientdata(tmpresult, clientdata)
	return get_user(self, tmpresult.value.userid.value)
end

function mymodule.get_new_user(self, clientdata)
	local result = get_blank_user(self)

	-- Special handling for case where no users exist yet
	local userlist = authenticator.list_users(self)
	if #userlist == 0 then
		-- There are no users yet, suggest some values
		result.value.userid.value = "root"
		result.value.username.value = "Admin account"
		result.value.roles.value = {"ADMIN"}
	end

	return result
end

function mymodule.read_user_without_roles(self, clientdata)
	local result = mymodule.read_user(self, clientdata)

	-- We don't allow a user to modify his own roles
	-- Since they can't modify roles, we should restrict the available options for home
	result.value.home.option = {""}
	local tmp1, tmp2 = roles.get_roles_perm(self, result.value.roles.value)
	table.sort(tmp2)
	for i,h in ipairs(tmp2) do
		if h ~= "/acf-util/logon/logoff" and h ~= "/acf-util/logon/logon" then
			result.value.home.option[#result.value.home.option+1] = h
		end
	end
	result.value.roles = nil

	return result
end

function mymodule.get_users(self)
	--List all users and their userinfo
	local users = {}
	local userlist = authenticator.list_users(self)
	table.sort(userlist)

	for x,user in pairs(userlist) do
		users[#users+1] = get_user(self, user)
	end
	return cfe({ type="group", value=users, label="User Accounts" })
end

function mymodule.get_delete_user(self, clientdata)
	local userid = cfe({ label="User id", value=clientdata.userid or "" })
	return cfe({ type="group", value={userid=userid}, label="Delete User" })
end

function mymodule.delete_user(self, deleteuser)
	deleteuser.errtxt = "Failed to delete user"
	if authenticator.delete_user(self, deleteuser.value.userid.value) then
		deleteuser.errtxt = nil
	end
	return deleteuser
end

function mymodule.list_lock_events(self, clientdata)
	return cfe({type="structure", value=session.list_events(self.conf.sessiondir), label="Lock events"})
end

function mymodule.get_unlock_user(self, clientdata)
	local retval = cfe({type="group", value={}, label="Unlock user"})
	retval.value.userid = cfe({ label="User id" })
	return retval
end

function mymodule.unlock_user(self, unlock)
	session.delete_events(self.conf.sessiondir, unlock.value.userid.value)
	return unlock
end

function mymodule.get_unlock_ip(self, clientdata)
	local retval = cfe({type="group", value={}, label="Unlock IP address"})
	retval.value.ip = cfe({ label="IP address" })
	return retval
end

function mymodule.unlock_ip(self, unlock)
	session.delete_events(self.conf.sessiondir, nil, unlock.value.ip.value)
	return unlock
end

return mymodule
