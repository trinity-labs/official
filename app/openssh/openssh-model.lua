local mymodule = {}

-- Load libraries
modelfunctions = require("modelfunctions")
posix = require("posix")
validator = require("acf.validator")
fs = require("acf.fs")
format = require("acf.format")

-- Set variables
local configfile = "/etc/ssh/sshd_config"
local processname = "sshd"
local packagename = "openssh"
local header = "SSH"

-- ################################################################################
-- LOCAL FUNCTIONS

-- return "Yes" or "No" on true/false or value as string
local function config_value(value)
	if type(value) == "boolean" then
		if value then
			return "yes"
		else
			return "no"
		end
	end
	return tostring(value)
end

local function validate_config(config)
	local success = true

	if not validator.is_ipv4(config.value.ListenAddress.value) then
		config.value.ListenAddress.errtxt = "Invalid IP"
		success = false
	end
	if not validator.is_port(config.value.Port.value) then
		config.value.Port.errtxt = "Invalid Port"
		success = false
	end

	return success, config
end

-- ################################################################################
-- PUBLIC FUNCTIONS

function mymodule.get_startstop(self, clientdata)
        return modelfunctions.get_startstop(processname)
end

function mymodule.startstop_service(self, startstop, action)
        return modelfunctions.startstop_service(startstop, action)
end

function mymodule.getstatus()
	return modelfunctions.getstatus(processname, packagename, header .. " status")
end

function mymodule.getconfigfile()
	return modelfunctions.getfiledetails(configfile)
end

function mymodule.setconfigfile(self, filedetails)
	return modelfunctions.setfiledetails(self, filedetails, {configfile})
end

function mymodule.read_config()
	local output = {}
	output.Port = cfe({ value=22, label="Port", seq=1 })
	output.ListenAddress = cfe({ value="0.0.0.0", label="Listen address", seq=2 })
	output.PermitRootLogin = cfe({ type="select", value="prohibit-password", label="Permit Root Login", option={"yes", "no", "prohibit-password", "without-password"}, seq=3 })
	output.PasswordAuthentication = cfe({ type="boolean", value=true, label="Password Authentication", seq=4 })
	output.UseDNS = cfe({ type="boolean", value=false, label="Use DNS", seq=5 })

	local config = format.parse_configfile(fs.read_file(configfile) or "")
	if config then
		output.Port.value = config.Port or output.Port.value
		output.ListenAddress.value = config.ListenAddress or output.ListenAddress.value
		output.PermitRootLogin.value = config.PermitRootLogin or output.PermitRootLogin.value
		output.PasswordAuthentication.value = not (config.PasswordAuthentication == "no")
		output.UseDNS.value = (config.UseDNS == "yes")
	end

	return cfe({ type="group", value=output, label="OpenSSH Config" })
end

function mymodule.update_config(self, config)
	local success, config = validate_config(config)

	if success then
		for name,val in pairs(config.value) do
			val.line = name.." "..config_value(val.value)
		end

		local lines = {}
		for line in string.gmatch(fs.read_file(configfile) or "", "([^\n]*)\n?") do
			for name,val in pairs(config.value) do
				if val.line and string.find(line, "^%s*#?%s*"..name) then
					if string.find(line, "^%s*#") then
						lines[#lines+1] = val.line
					else
						line = val.line
					end
					val.line = nil
				end
			end
			lines[#lines+1] = line
		end

		for name,val in pairs(config.value) do
			if val.line then
				lines[#lines+1] = val.line
				val.line = nil
			end
		end
		fs.write_file(configfile, string.gsub(table.concat(lines, "\n"), "\n+$", ""))
	else
		config.errtxt = "Failed to save config"
	end

	return config
end

function mymodule.list_conn_peers()
	local output = cfe({ type="structure", value={}, label="Connected peers" })
	local netstat = {}
	local ps = {}
	config = mymodule.read_config()

	local f = modelfunctions.run_executable({"ps"})
	for i,line in ipairs(format.search_for_lines(f, "sshd:")) do
		local pid, user, tty = string.match(line, "^%s*(%d+)%s+%S+%s+%S+%s+%S+%s+([^@ ]+)@?(%S*)")
		if pid then
			ps[pid] = {user=user, tty=tty}
		end
	end

	f = modelfunctions.run_executable({"netstat", "-tnp"})
	local flines = format.search_for_lines(f, "ESTABLISHED")
	local g = modelfunctions.run_executable({"netstat", "-t"})
	local glines = format.search_for_lines(g, "ESTABLISHED")
	for i,line in ipairs(flines) do
		local loc, peer, pid = string.match(line, "^%S+%s+%S+%s+%S+%s+(%S+)%s+(%S+)%s+%S+%s+(%d+)")
		if loc then
			peer = string.match(peer, "%d+%.%d+%.%d+%.%d+")
			if string.find(loc, ":"..config.value.Port.value.."$") and peer then
				if not netstat[peer] then
					local name = string.match(glines[i], "^%S+%s+%S+%s+%S+%s+%S+%s+(%S+)")
					name = string.gsub(name, ":.*", "")
					netstat[peer] = {cnt=0, name=name, tty={}}
				end
				netstat[peer].cnt = netstat[peer].cnt + 1
				if ps[pid] then
					-- For root, the pid will match and contain the tty
					-- For other users, we will find the tty in another process soon after
					netstat[peer].tty[#netstat[peer].tty+1] = {user=ps[pid].user, tty=ps[pid].tty}
					if ps[pid].tty == "" then
						for j=tostring(pid)+1, tostring(pid)+5 do
							local p = tostring(j)
							if ps[p] and ps[p].user == ps[pid].user then
								netstat[peer].tty[#netstat[peer].tty].tty = ps[p].tty
								break
							end
						end
					end
				end
			end
		end
	end

	for peer,v in pairs(netstat) do
		output.value[#output.value+1] = v
		output.value[#output.value].host = peer
	end

	return output
end

function mymodule.list_users()
	local users = {"root"}
	-- The only users we're going to worry about in this ACF are root and ones with home directories
	for user in posix.files("/home") do
		if fs.is_dir("/home/" .. user) and not string.find(user, "^%.") then users[#users + 1] = user end
	end
	table.sort(users)
	return cfe({ type="list", value=users, label="User list" })
end

local function parseauthline(line)
	local retval = {}
	local words = format.string_to_table(line, "%s")
	if words[1] and string.match(words[1], "^ssh%-%ws%w$") then
		retval.perm = ""
		retval.key = words[2]
		retval.id = table.concat(words, " ", 3)
	elseif words[2] and string.match(words[2], "^ssh%-%ws%w$") then
		retval.perm = words[1]
		retval.key = words[3]
		retval.id = table.concat(words, " ", 4)
	else
		retval = nil
	end
	return retval
end

function mymodule.list_auths(user)
	user = user or "root"
	local cmdresult = cfe({ type="group", value={}, label="Authorized Key List" })
	cmdresult.value.user = cfe({ value=user, label="User" })
	cmdresult.value.auth = cfe({ type="structure", value={}, label="Authorized Keys" })
	if not user == "root" and (string.find(user, "/") or not fs.is_dir("/home/"..user)) then
		cmdresult.value.user.errtxt = "Invalid user"
	else
		local file = "/"..user.."/.ssh/authorized_keys"
		if user ~= "root" then file = "/home"..file end
		local data = fs.read_file(file) or ""
		for line in string.gmatch(data, "([^\n]+)\n?") do
			table.insert(cmdresult.value.auth.value, parseauthline(line))
		end
	end
	table.sort(cmdresult.value.auth.value, function(a,b) return a.id < b.id end)
	return cmdresult
end

function mymodule.get_delete_auth(self, clientdata)
	local retval = {}
	retval.user = cfe({ value=clientdata.user or "root", label="User" })
	retval.auth = cfe({ value=clientdata.auth or "", label="Authorized Key" })
	return cfe({ type="group", value=retval, label="Delete Authorized Key" })
end

function mymodule.delete_auth(self, delauth)
	local user = delauth.value.user.value
	delauth.value.user.errtxt = "User not found"
	delauth.errtxt = "Failed to delete key"
	if user == "root" or (not string.find(user, "/") and fs.is_dir("/home/"..user)) then
		delauth.value.user.errtxt = nil
		delauth.value.auth.errtxt = "Key not found"

		local file = "/"..user.."/.ssh/authorized_keys"
		if user ~= "root" then file = "/home"..file end
		local data = fs.read_file(file)
		if data then
			local newdata = {}
			for line in string.gmatch(data, "([^\n]+)\n?") do
				local val = parseauthline(line)
				if val.id == delauth.value.auth.value then
					delauth.errtxt = nil
					delauth.value.auth.errtxt = nil
				else
					newdata[#newdata + 1] = line
				end
			end
			if not delauth.errtxt then
				fs.write_file(file, table.concat(newdata, "\n"))
			end
		end
	end
	return delauth
end

function mymodule.get_auth(user)
	local cmdresult = cfe({ type="group", value={}, label="Authorized Key List" })
	cmdresult.value.user = cfe({ value=user or "root", label="User", seq=1 })
	if user then
		cmdresult.value.user.readonly=true
	end
	cmdresult.value.cert = cfe({ type="longtext", label="SSH Certificate Contents", seq=2 })
	return cmdresult
end

function mymodule.create_auth(self, authstr)
	authstr.value.user.value = authstr.value.user.value or "root"
	local success = true
	if not authstr.value.user.value == "root" and (string.find(authstr.value.user.value, "/") or not fs.is_dir("/home/"..authstr.value.user.value)) then
		authstr.value.user.errtxt = "Invalid user"
		success = false
	end
	-- parse the current file to get existing keys
	local file = "/"..authstr.value.user.value.."/.ssh/authorized_keys"
	if authstr.value.user.value ~= "root" then file = "/home"..file end
	local lines = {}
	local auths = {}
	if success then
		local data = fs.read_file(file) or ""
		for line in string.gmatch(data, "([^\n]+)\n?") do
			auths[#auths+1] = parseauthline(line)
			lines[#lines+1] = line
		end
	end
	local certs = {}
	-- not sure how to validate the cert
	if not string.match(authstr.value.cert.value, "^%s*ssh") then
		authstr.value.cert.errtxt = "Invalid format - must start with 'ssh-...'"
		success = false
	else
		-- try to handle certs that wrap lines and multiple certs in the entry
		for line in string.gmatch(format.dostounix(authstr.value.cert.value), "([^\n]*)\n?") do
			if string.match(line, "^%s*ssh") then
				certs[#certs+1] = line
			elseif #certs > 0 then
				certs[#certs] = certs[#certs] .. line
			end
		end
	end
	for i,cert in ipairs(certs) do
		local val = parseauthline(cert)
		if not val then
			authstr.value.cert.errtxt = "Invalid format"
			success = false
			break
		end
		for j,au in ipairs(auths) do
			if val.id == au.id or val.key == au.key then
				authstr.value.cert.errtxt = "This key / ID already exists"
				success = false
				break
			end
		end
		if success then
			lines[#lines+1] = cert
			auths[#auths+1] = val
		else
			break
		end
	end
	if success then
		fs.write_file(file, table.concat(lines, "\n") or "")
	else
		authstr.errtxt = "Failed to add key"
	end
	return authstr
end

function mymodule.get_logfile(self, clientdata)
	local retval = cfe({ type="group", value={}, label="Log File Configuration" })
	retval.value.facility = cfe({value="auth", label="Syslog Facility"})
	retval.value.grep = cfe({ value="sshd", label="Grep" })

	local config = format.parse_configfile(fs.read_file(configfile) or "")
	if config then
		if config.SyslogFacility then
			retval.value.facility.value = config.SyslogFacility:lower()
		end
	end
	return retval
end

return mymodule
