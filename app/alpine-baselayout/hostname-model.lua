-- hostname model methods
local mymodule = {}

fs = require("acf.fs")
modelfunctions = require("modelfunctions")

mymodule.get = function (fqdn)
	local n
	if fqdn then
		n = modelfunctions.run_executable({"hostname", "-f"})
	end
	if not n or n == "" then
		n = modelfunctions.run_executable({"hostname"})
	end
	if not n or n == "" then
		n = "unknown"
	end

	return cfe({value=n, label="Hostname"})
end


mymodule.read_name = function ()
	return cfe({ type="group", value={hostname=mymodule.get(false)}, label="Hostname" })
end

mymodule.update_name = function(self, name)
	local success = true

	-- Hostname must be less than 64 characters, characters in set 0-9a-z-, and not start/end with -
	if string.len(name.value.hostname.value) == 0 or string.len(name.value.hostname.value) > 63 then
		name.value.hostname.errtxt = "Illegal length"
		success = false
	elseif string.find(name.value.hostname.value, "[^-0-9a-zA-Z]") then
		name.value.hostname.errtxt = "Contains illegal character"
		success = false
	elseif string.find(name.value.hostname.value, "^-") or string.find(name.value.hostname.value, "-$") then
		name.value.hostname.errtxt = "Illegal start/end character"
		success = false
	end

	if success then
		fs.write_file("/etc/hostname", name.value.hostname.value)
		modelfunctions.run_executable({"hostname", "-F", "/etc/hostname"})
	else
		name.errtxt = "Failed to set hostname"
	end

	return name
end

return mymodule
