local mymodule = {}

modelfunctions = require("modelfunctions")
fs = require("acf.fs")

local configfile = "/etc/modules"

function mymodule.read_modules()
	local retval = modelfunctions.run_executable({"lsmod"})
	return cfe({ type="longtext", value=retval, label="Modules List" })
end

function mymodule.read_file()
	return modelfunctions.getfiledetails(configfile)
end

function mymodule.write_file(self, filedetails)
	return modelfunctions.setfiledetails(self, filedetails, {configfile})
end

function mymodule.get_reloadmodules(self, clientdata)
	local actions = {}
	actions[1] = "restart"
	local service = cfe({ type="hidden", value="modules", label="Service Name" })
	local startstop = cfe({ type="group", label="Reload Modules", value={servicename=service}, option=actions, errtxt=errtxt })

	return startstop
end

function mymodule.reloadmodules(self, startstop)
	return modelfunctions.startstop_service(startstop, "restart")
end

return mymodule
