-- Roles/Group functions
local mymodule = {}

modelfunctions = require("modelfunctions")
authenticator = require("authenticator")
roles = require("roles")

-- Return roles/permissions for specified user
mymodule.get_user_roles = function(self, userid)
	local userinfo = authenticator.get_userinfo(self, userid) or {}
	rls = cfe({ type="list", value=userinfo.roles or {}, label="Roles" })
	permissions = cfe({ type="structure", value=roles.get_roles_perm(self, rls.value), label="Permissions" })
	return cfe({ type="group", value={roles=rls, permissions=permissions}, label="Roles/Permission list for "..userid })
end

-- Return permissions for specified role
mymodule.get_role_perms = function(self, role)
	return cfe({ type="structure", value=roles.get_role_perm(self, role), label="Permissions" })
end

-- Return list of all permissions
mymodule.get_perms_list = function(self)
	return cfe({ type="structure", value=roles.get_all_permissions(self), label="All Permissions" })
end

mymodule.view_roles = function(self)
	local defined_roles, default_roles = roles.list_roles(self)
	local defined_roles_cfe=cfe({ type="list", value=defined_roles, label="Locally-defined roles" })
	local default_roles_cfe=cfe({ type="list", value=default_roles, label="System-defined roles" })

	return cfe({ type="group", value={defined_roles=defined_roles_cfe, default_roles=default_roles_cfe}, label="Roles" })
end

mymodule.getpermissions = function(self, clientdata)
	local role_cfe = cfe({ value=clientdata.role or "", label="Role", seq=1 })

	local tmp, all_perms = roles.get_all_permissions(self)
	table.sort(all_perms)
	local my_perms = {}
	local default_perms = {}

	if clientdata.role then
		role_cfe.readonly = true
		local tmp
		tmp, my_perms, default_perms = roles.get_role_perm(self, clientdata.role)
		my_perms = my_perms or {}
		default_perms = default_perms or {}
		if #default_perms > 0 then
			-- Mark the default permissions as disabled
			local rev = {}
			for i,d in ipairs(default_perms) do
				rev[d] = i
			end
			local newall = {}
			for i,p in ipairs(all_perms) do
				local tmp = {value=p, label=p}
				if rev[p] then
					tmp.disabled = true
				end
				newall[#newall+1] = tmp
			end
			all_perms = newall
		end
	end

	local permissions_cfe = cfe({ type="multi", value=my_perms, option=all_perms, label="Role permissions", seq=2 })

	return cfe({ type="structure", value={role=role_cfe, permissions=permissions_cfe} })
end

mymodule.setnewpermissions = function(self, permissions, action)
	return mymodule.setpermissions(self, permissions, action, true)
end

mymodule.setpermissions = function(self, permissions, action, newrole)
	-- Validate entries and create error strings
	local result = true
	if newrole then
		-- make sure not overwriting role
		local defined_roles, default_roles = roles.list_roles(self)
		local reverseroles = {}
		for i,role in ipairs(defined_roles) do reverseroles[role] = i end
		for i,role in ipairs(default_roles) do reverseroles[role] = i end
		if reverseroles[permissions.value.role.value] then
			result = false
			permissions.value.role.errtxt = "Role already exists"
			permissions.errtxt = "Failed to create role"
		end
	end
	-- Try to set the value
	if result==true then
		-- Remove the default permissions
		local reversepermissions = {}
		for i,p in ipairs(permissions.value.permissions.value) do
			reversepermissions[p] = i
		end
		for i,p in ipairs(permissions.value.permissions.option) do
			if p.disabled then
				reversepermissions[p.value] = nil
			end
		end
		local permissionstable = {}
		for p in pairs(reversepermissions) do
			permissionstable[#permissionstable+1] = p
		end

		result, permissions.value.role.errtxt = roles.set_role_perm(self, permissions.value.role.value, nil, permissionstable)
		if not result then
			permissions.errtxt = "Failed to save role"
		end
	end

	return permissions
end

mymodule.get_delete_role = function(self, clientdata)
	local defined_roles, default_roles = roles.list_roles(self)
	local role = cfe({ type="select", value = clientdata.role or "", label="Role", option=defined_roles })
	return cfe({ type="group", value={role=role}, label="Delete Role" })
end

mymodule.delete_role = function(self, role)
	local result, cmdresult = roles.delete_role(self, role.value.role.value)
	if not result then
		role.value.role.errtxt = cmdresult
		role.errtxt = "Failed to Delete Role"
	else
		-- remove the just deleted role
		for i,r in ipairs(role.value.role.option) do
			if r == role.value.role.value then
				role.value.role.value =""
				role.value.role.option[i] = nil
				break
			end
		end
	end
	return role
end

return mymodule
