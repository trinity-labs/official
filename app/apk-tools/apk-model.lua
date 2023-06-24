-- acf model for packages (apk)
local mymodule = {}
modelfunctions = require("modelfunctions")
posix = require("posix")
fs = require("acf.fs")
format = require("acf.format")

local configfile = "/etc/apk/repositories"
local worldfile = "/etc/apk/world"
local cachelink = "/etc/apk/cache"
local lbuconffile = "/etc/lbu/lbu.conf"

local repo = nil
local install_cache = false
local upgrade_cache = false
local toplevel

-- ################################################################################
-- LOCAL FUNCTIONS

local function gettoplevel()
	if not toplevel then
		toplevel = {}
		local top = format.string_to_table(fs.read_file(worldfile) or "", "%s+")
		for i,name in ipairs(top) do
			toplevel[name] = i
		end
	end
	return toplevel
end

local reload_upgrades = function()
	if repo then
		-- clear out upgrade info
		for name,value in pairs(repo) do
			if value then
				value.upgrade = nil
			end
		end
		-- read in which need upgrades
		local f = modelfunctions.run_executable({"apk", "version", "-l", "<"})
		for line in string.gmatch(f, "[^\n]+") do
			local name = string.match(line, "(%S+)%-%d")
			if name and repo[name] then
				repo[name].upgrade = true
			end
		end
		upgrade_cache = true
	end
	return repo
end

local reload_installed = function()
	if repo then
		-- clear out installed info
		for name,value in pairs(repo) do
			if value then
				value.installed = nil
				value.comment = nil
			end
		end
		-- read in which are installed
		local f = modelfunctions.run_executable({"apk", "info", "-vv"})
		for line in string.gmatch(f, "[^\n]+") do
			local name, ver, comment = string.match(line, "(%S+)%-(%d+%S*)%s+%-%s+(.*)")
			if name then
				if not repo[name] then
					repo[name] = {}
				end
				repo[name].installed = ver
				repo[name].comment = comment
			end
		end
		install_cache = true
	end
	return repo
end

local repository = function()
	if not repo then
		-- read in all of the packages
		local f,errtxt = modelfunctions.run_executable({"apk", "search"})
		repo = {}
		install_cache = false
		upgrade_cache = false
		for line in string.gmatch(f, "[^\n]+") do
			local name, ver = string.match(line, "(.*)%-(%d+.*)")
			if name and (not repo[name] or repo[name].version < ver) then
				repo[name] = {}
				repo[name].version = ver
			end
		end
	end
	if not install_cache then
		reload_installed()
	end
	if not upgrade_cache then
		reload_upgrades()
	end
	return repo
end

-- Find all the packages that this package depends on (using recursion)
local find_dependents
find_dependents = function(package)
	repo = repo or repository()
	if not repo[package] then
		return {}
	end
	if not repo[package].dependents then
		repo[package].dependents = {}
		local f = modelfunctions.run_executable({"apk", "info", "-R", package})
		for line in string.gmatch(f, "[^\n]+") do
			if not line:find(":") and not line:find("^%s*$") then
				table.insert(repo[package].dependents, line)
				for i,dep in ipairs(find_dependents(line, saved, output)) do
					table.insert(repo[package].dependents, dep)
				end
			end
		end
	end
	return repo[package].dependents
end

local function upgrade_available(package)
	local retval = false
	repo = repo or repository()
	if repo[package] and repo[package].upgrade then
		retval = true
	else -- check the dependents
		for i,dep in ipairs(find_dependents(package)) do
			if repo[dep] and repo[dep].upgrade then
				retval = true
				break
			end
		end
	end
	return retval
end

local resetpermissions = function(self)
	if self.sessiondata then self.sessiondata.menu = nil end
	if self.sessiondata then self.sessiondata.permissions = nil end
end

-- ################################################################################
-- PUBLIC FUNCTIONS

mymodule.get_loaded_packages = function()
	repo = repository()
	toplevel = gettoplevel()

	-- read in the loaded packages
	local top = cfe({ type="structure", value={}, label="Top Level Packages"})
	local depend = cfe({ type="structure", value={}, label="Dependent Packages"})
	for name,value in pairs(repo) do
		if value.installed then
			local temp = {}
			temp.name = name
			temp.version = value.installed
			temp.description = value.comment
	                temp.upgrade = value.upgrade
			if toplevel[name] then
				top.value[#top.value+1] = temp
			else
				depend.value[#depend.value+1] = temp
			end
		end
	end
	table.sort(top.value, function(a,b) return (a.name < b.name) end)
	table.sort(depend.value, function(a,b) return (a.name < b.name) end)
	return cfe({ type="group", value={toplevel=top, dependent=depend}, label="Installed Packages" })
end

local handle_pagination_and_filtering = function(self, clientdata, packages)
	local retval = cfe({ type="group", value={} })
	retval.value.page = cfe({ value=0, label="Page Number", descr="0 indicates ALL", key=true })
	retval.value.pagesize = cfe({ value=10, label="Page Size", key=true })
	retval.value.rowcount = cfe({ value=0, label="Row Count" })
	-- orderby must be an array of tables with column name and direction
	retval.value.orderby = cfe({ type="structure", value={{column="name", direction="asc"}}, label="Order By", key=true })
	-- filter is a table with a string filter for each column
	retval.value.filter = cfe({ type="structure", value={name="", version=""}, label="Filter", key=true })
	self.handle_clientdata(retval, clientdata)
	retval.value.result = cfe({ type="structure", value={} })

	-- Process the incoming page data
	local page = tonumber(retval.value.page.value) or 0
	retval.value.page.value = page
	local pagesize = tonumber(retval.value.pagesize.value) or 10
	retval.value.pagesize.value = pagesize

	local result = {}
	for name,value in pairs(packages) do
		local temp = {}
		temp.name = name
		temp.version = value.installed or value.version
		temp.upgrade = value.upgrade
		temp.description = value.comment

		-- Filter
		for c,f in pairs(retval.value.filter.value) do
			if temp[c] and f ~= "" and not string.find(temp[c], format.escapemagiccharacters(f)) then
				temp = nil
				break
			end
		end

		result[#result + 1] = temp
	end

	-- Sort
	if #result > 0 then
		local function createsort(column, descending, equal)
			return function(a,b)
				if a[column] == b[column] then
					return equal(a,b)
				end
				if descending then
					return tostring(a[column]) > tostring(b[column])
				end
				return tostring(a[column]) < tostring(b[column])
			end
		end
		local sortfunction = function(a,b) return false end
		if #retval.value.orderby.value == 0 then
			sortfunction = createsort("name", true, sortfunction)
		else
			local columns = {name=true, version=true, upgrade=true}
			local directions = {desc=true, DESC=true}
			for i=#retval.value.orderby.value,1,-1 do
				local orderby = retval.value.orderby.value[i]
				if columns[orderby.column] then
					sortfunction = createsort(orderby.column, directions[orderby.direction], sortfunction)
				end
			end
		end
		table.sort(result, sortfunction)
	end

	-- Paginate
	retval.value.rowcount.value = #result
	if page > 0 then
		for i=((page-1)*pagesize+1), (page*pagesize) do
			retval.value.result.value[#retval.value.result.value+1] = result[i]
		end
	else
		retval.value.result.value = result
	end

	return retval
end

mymodule.get_available_packages = function(self, clientdata)
	repo = repository()
	local packages = {}
	-- available are all except same version installed
	for name,value in pairs(repo) do
		if value.version and (not value.installed or value.upgrade) then
			packages[name] = value
		end
	end
	local retval = handle_pagination_and_filtering(self, clientdata, packages)
	retval.label = "Available Packages"
	if retval.value.result then retval.value.result.label = "Available Packages" end
	return retval
end

mymodule.get_toplevel_packages = function(self, clientdata)
	repo = repository()
	toplevel = gettoplevel()
	local packages = {}
	for name,value in pairs(repo) do
		if value.installed and toplevel[name] then
			packages[name] = value
		end
	end
	local retval = handle_pagination_and_filtering(self, clientdata, packages)
	retval.label = "Top Level Packages"
	if retval.value.result then retval.value.result.label = "Top Level Packages" end
	return retval
end

mymodule.get_dependent_packages = function(self, clientdata)
	repo = repository()
	toplevel = gettoplevel()
	local packages = {}
	for name,value in pairs(repo) do
		if value.installed and not toplevel[name] then
			packages[name] = value
		end
	end
	local retval = handle_pagination_and_filtering(self, clientdata, packages)
	retval.label = "Dependent Packages"
	if retval.value.result then retval.value.result.label = "Dependent Packages" end
	return retval
end

mymodule.get_delete_package = function(self, clientdata)
	local result = {}
	result.package = cfe({ label="Package" })

	return cfe({ type="group", value=result, label="Result of Delete" })
end

mymodule.delete_package = function(self, deleterequest)
	deleterequest.descr, deleterequest.errtxt = modelfunctions.run_executable({"apk", "del", deleterequest.value.package.value}, true)
	if deleterequest.errtxt == "" then
		deleterequest.errtxt = "Failed to delete package."
	end
	-- Destroy menu and permissions info in session so recalculated
	resetpermissions(self)

	return deleterequest
end

mymodule.get_install_package = function(self, clientdata)
	local result = {}
	result.package = cfe({ label="Package" })

	return cfe({ type="group", value=result, label="Result of Install" })
end

mymodule.install_package = function(self, installrequest)
	installrequest.descr, installrequest.errtxt = modelfunctions.run_executable({"apk", "add", installrequest.value.package.value}, true)
	if not installrequest.errtxt then
		-- Destroy menu and permissions info in session so recalculated
		resetpermissions(self)
	end

	return installrequest 
end

mymodule.get_upgrade_package = function(self, clientdata)
	local result = {}
	result.package = cfe({ label="Package" })

	return cfe({ type="group", value=result, label="Result of Upgrade" })
end

mymodule.upgrade_package = function(self, upgraderequest)
	upgraderequest.descr, upgraderequest.errtxt = modelfunctions.run_executable({"apk", "fix", "-u", upgraderequest.value.package.value}, true)
	if upgraderequest.errtxt == "" then
		upgraderequest.errtxt = "Failed to upgrade package."
	end
	-- Destroy menu and permissions info in session so recalculated
	resetpermissions(self)

	return upgraderequest
end

mymodule.get_update_all = function(self, clientdata)
	local result = {}

	return cfe({ type="group", value=result, label="Result of Update" })
end

mymodule.update_all = function(self, updaterequest)
	updaterequest.descr, updaterequest.errtxt = modelfunctions.run_executable({"apk", "update"}, true)
	if updaterequest.errtxt == "" then
		updaterequest.errtxt = "Failed to update index."
	end

	return updaterequest
end

mymodule.get_upgrade_all = function(self, clientdata)
	local result = {}

	return cfe({ type="group", value=result, label="Result of Upgrade" })
end

mymodule.upgrade_all = function(self, upgraderequest)
	upgraderequest.descr, upgraderequest.errtxt = modelfunctions.run_executable({"apk", "upgrade", "-U"}, true)
	if upgraderequest.errtxt == "" then
		upgraderequest.errtxt = "Failed to upgrade packages."
	end
	-- Destroy menu and permissions info in session so recalculated
	resetpermissions(self)

	return upgraderequest
end

mymodule.get_cache = function()
	local cache = {}
	cache.enable = cfe({ type="boolean", value=false, label="Enable Cache" })
	cache.directory = cfe({ label="Cache Directory" })
	local link = posix.stat(cachelink, "type")
	if link == "link" then
		cache.enable.value = true
		cache.directory.value = posix.readlink(cachelink)
	else
		if link then
			cache.enable.errtxt = cachelink.." exists but is not a link"
		end
		local lbu_media = format.parse_ini_file(fs.read_file(lbuconffile), "", "LBU_MEDIA")
		if lbu_media then
			cache.directory.value = "/media/"..lbu_media.."/cache"
		end
	end
	return cfe({ type="group", value=cache, label="Cache Settings" })
end

mymodule.update_cache = function(self, cache)
	cache.value.enable.errtxt = nil
	if not cache.value.enable.value then
		os.remove(cachelink)
	else
		local success = false
		cache.errtxt = "Failed to set cache"
		if cache.value.directory.value == "" then
			cache.value.directory.errtxt = "Directory must be defined"
		else
			local dir = posix.stat(cache.value.directory.value, "type")
			if dir and dir ~= "directory" then
				cache.value.directory.errtxt = "Path exists but is not a directory"
			elseif not dir then
				success = fs.create_directory(cache.value.directory.value)
				if not success then
					cache.value.directory.errtxt = "Failed to create directory"
				end
			else
				success = true
			end
		end
		if success then
			os.remove(cachelink)
			posix.link(cache.value.directory.value, cachelink, true)
			cache.errtxt = nil
		end
	end
	return cache
end

mymodule.get_configfile = function()
	return modelfunctions.getfiledetails(configfile)
end

mymodule.update_configfile = function(self, newconfig)
	return modelfunctions.setfiledetails(self, newconfig, {configfile})
end

mymodule.get_package_details = function(package)
	repo = repo or repository()
	local details = {}
	details.package = cfe({ value=package, label="Package" })
	details.version = cfe({ label="Available Version" })
	details.installed = cfe({ label="Installed Version" })
	details.comment = cfe({ label="Description" })
	details.webpage = cfe({ label="Web Page" })
	details.size = cfe({ label="Size" })
	details.upgrade = cfe({ label="Upgrade Details" })
	if not repo[package] then
		details.package.errtxt = "Invalid package"
	else
		details.version.value = repo[package].version
		if repo[package].installed then
			details.installed.value = repo[package].installed
			details.comment.value = repo[package].comment
			local cmdresult = format.string_to_table((modelfunctions.run_executable({"apk", "info", "-ws", package})), "\n")
			for i,line in ipairs(cmdresult) do
				if string.find(line, " webpage:$") then
					details.webpage.value = cmdresult[i+1] or ""
				elseif string.find(line, " size:$") then
					details.size.value = cmdresult[i+1] or ""
				end
			end
			local dependents = find_dependents(package)
			table.insert(dependents, 1, package)
			local revdeps = {}
			details.upgrade.value = {}
			for i,val in ipairs(dependents) do
				if not revdeps[val] then
					revdeps[val] = true
					if repo[val] and repo[val].upgrade then
						table.insert(details.upgrade.value, val.." "..repo[val].installed.." -> "..repo[val].version)
					end
				end
			end
			details.upgrade.value = table.concat(details.upgrade.value, "\n")
		end
	end
	return cfe({ type="group", value=details, label="Package Details" })
end

return mymodule
