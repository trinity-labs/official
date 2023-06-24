local mymodule = {}

posix = require("posix")
modelfunctions = require("modelfunctions")
processinfo = require("acf.processinfo")
fs = require("acf.fs")

local configpath = "/etc/runlevels/"
local runlevels = {}
for f in posix.files(configpath) do
	if f~="." and f~=".." and fs.is_dir(configpath..f) then
		runlevels[#runlevels+1] = f
	end
end
table.sort(runlevels)

local config

mymodule.status = function()
	if not config then
		config = processinfo.read_initrunlevels()
		for i,c in pairs(config) do
			c.actions, c.description = processinfo.daemon_actions(c.servicename)
			c.status = processinfo.daemoncontrol(c.servicename, "status")
			if c.status then
				c.status = string.match(c.status, "status: (.*)")
			end
		end
	end
	return cfe({ type="structure", value=config, label="Init Runlevels" })
end

mymodule.read_runlevels = function(self, clientdata)
	local servicename = clientdata.servicename
	local value = {}
	value.servicename = cfe({ value=servicename or "", label="Service Name", seq=1 })
	if servicename then value.servicename.readonly = true end
	value.runlevels = cfe({ type="multi", value={}, label="Service Runlevels", option=runlevels, seq=2 })

	-- read in the value for the servicename
	config = config or processinfo.read_initrunlevels()
	for i,conf in ipairs(config) do
		if conf.servicename == servicename then
			value.runlevels.value = conf.runlevels
			break
		end
	end

	return cfe({ type="group", value=value, label="Service Runlevels"})
end

mymodule.update_runlevels = function(self, service)
	local success = modelfunctions.validatemulti(service.value.runlevels)
	service.value.servicename.errtxt = "Invalid service"
	for name in posix.files("/etc/init.d") do
		if name == service.value.servicename.value then
			success = true
			service.value.servicename.errtxt = nil
		end
	end
	if success then
		local reverserunlevels = {}
		for i,lev in ipairs(service.value.runlevels.value) do
			reverserunlevels[lev] = i
		end
		local delrunlevels = {}
		for i,lev in ipairs(runlevels) do
			if not reverserunlevels[lev] then
				delrunlevels[#delrunlevels+1] = lev
			end
		end
		service.descr = {}
		service.errtxt = {}
		service.descr[#service.descr+1], service.errtxt[#service.errtxt+1] = processinfo.delete_runlevels(service.value.servicename.value, delrunlevels)
		service.descr[#service.descr+1], service.errtxt[#service.errtxt+1] = processinfo.add_runlevels(service.value.servicename.value, service.value.runlevels.value)
		service.descr = table.concat(service.descr, "\n")
		service.errtxt = table.concat(service.errtxt, "\n")
		if service.errtxt and string.find(service.errtxt, "^%s*$") then
			service.errtxt = nil
		end
	else
		service.errtxt = "Failed to set runlevels"
	end

	return service
end

function mymodule.get_startstop(self, clientdata)
	return modelfunctions.get_startstop(clientdata.servicename)
end

function mymodule.startstop_service(self, startstop, action)
	return modelfunctions.startstop_service(startstop, action)
end

return mymodule
