-- alpineversion model methods
local mymodule = {}

fs = require("acf.fs")

mymodule.get = function ()
	local liboutput = fs.read_file("/etc/alpine-release")
	if (liboutput == nil) or (liboutput == "") then
		liboutput = "Unknown version"
	end
	return cfe({ value=liboutput, label="Alpine version" })
end

return mymodule
