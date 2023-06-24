local mymodule = {}

posix = require("posix")
modelfunctions = require("modelfunctions")
fs = require("acf.fs")
format = require("acf.format")
processinfo = require("acf.processinfo")
validator = require("acf.validator")

-- There are two options of how to allow users to specify the type of certificate they want - the request extensions
-- and the ca signing extensions.  We have opted for making all requests look the same (same extensions) and defining
-- different ca sections for the different types of certificates.  The ca section to use when signing the request is
-- actually stored in the request filename.  The request filename is in the following format: 
-- 	'username'.'ca section name'.'common name'.csr

local packagename = "openssl"
local configfile = "openssl-ca-acf.cnf"
local requestdir = "req/"
local certdir = "cert/"
local openssldir = "/etc/ssl/"
local basedir = openssldir

-- Save the config in a variable so isn't loaded each and every time needed
local config = nil

-- list of request entries that can be edited
local short_names = { countryName="C", stateOrProvinceName="ST", localityName="L", organizationName="O", organizationalUnitName="OU", commonName="CN" }

-- list of entries that may be found in cert extensions section
local extensions = { "basicConstraints", "nsCertType", "nsComment", "keyUsage", "subjectKeyIdentifier",
			"authorityKeyIdentifier", "subjectAltName", "issuerAltName" }
-- list of entries that must be found in ca section (used to define our certificate types)
local ca_mandatory_entries = { "new_certs_dir", "certificate", "private_key", "default_md", "database", "serial", "policy", "default_days" }

local initializecfe = function(self, clientdata, label)
	local retval = cfe({ type="group", value={}, label=label or "" })
	-- use a table as a dummy value to indicate it has not been overridden
	retval.value.cadir = cfe({ type="hidden", value={}, label="CA Directory", key=true })
	self.handle_clientdata(retval, clientdata)
	-- Restore the cadir from the sessiondata in order to make it persistent
	if type(retval.value.cadir.value) == "table" then
		if self.sessiondata and self.sessiondata.openssl_cadir then
			retval.value.cadir.value = self.sessiondata.openssl_cadir
		else
			retval.value.cadir.value = ""
		end
	end

	basedir = openssldir
	-- Make sure cadir does not contain ".." to ensure stays within openssldir
	if string.find(retval.value.cadir.value, "%.%.") then
		retval.value.cadir.errtxt = "Invalid Directory"
	elseif retval.value.cadir.value ~= "" then
		basedir = string.gsub(basedir..retval.value.cadir.value.."/", "/+", "/")
		-- Report back cleaned up value
		retval.value.cadir.value = string.match(basedir, openssldir.."(.*)/$") or ""
	end
	-- Save the cadir in the sessiondata in order to make it persistent
	if self.sessiondata then
		self.sessiondata.openssl_cadir = retval.value.cadir.value
	end
	return retval
end

-- Create a cfe with the distinguished name defaults
local getdefaults = function(self, clientdata)
	local defaults = initializecfe(self, clientdata, "OpenSSL Request")
	config = config or format.parse_ini_file(fs.read_file(basedir..configfile) or "")
	local distinguished_name = config.req.distinguished_name or ""

	-- Define the order of the parameters in the form
	local order = { "countryName", "C", "stateOrProvinceName", "ST", "localityName", "L", "organizationName", "O",
		"organizationalUnitName", "OU", "commonName", "CN", "emailAddress" }
	local reverseorder = {}
	for i,o in ipairs(order) do reverseorder[o] = i end

	-- Get the distinguished name defaults
	for name,value in pairs(config[distinguished_name]) do
		if nil == string.find(name, "_") then
			defaults.value[name] = cfe({ label=value,
			value=config[distinguished_name][name .. "_default"] or "", seq=reverseorder[name] or 90 })
		end
	end

	return defaults
end

-- Validate the values of distinguished names using the min/max found in the config file
local validate_distinguished_names = function(values)
	config = config or format.parse_ini_file(fs.read_file(basedir..configfile) or "")
	local distinguished_name = config.req.distinguished_name or ""
	local success = true

	for name,value in pairs(values.value) do
		if string.find(value.value, "[#]") then
			value.errtxt = "Value cannot contain #"
			success = false
		end

		-- check min, but empty is allowed
		local min = config[distinguished_name][name.."_min"]
		if min and value.value and #value.value < tonumber(min) and #value.value > 0 then
			value.errtxt = "Value too short"
			success = false
		end
		local max = config[distinguished_name][name.."_max"]
		if max and value.value and #value.value > tonumber(max) then
			value.errtxt = "Value too long"
			success = false
		end
	end
	return success, values
end

-- Write distinguished name defaults to config file
local write_distinguished_names = function(file, values, ignorevalues)
	local reverseignore = {}
	for i,value in ipairs(ignorevalues) do reverseignore[value]=i end
	config = config or format.parse_ini_file(file)
	local distinguished_name = config.req.distinguished_name or ""

	for name,value in pairs(values.value) do
		if not reverseignore[name] then
			local wname = name.."_default"
			file = format.update_ini_file(file, distinguished_name, wname, value.value)
		end
	end
	config = nil
	return file
end

local create_subject_string = function(values, ignorevalues)
	local outstr = {}
	local reverseignore = {}
	for i,value in ipairs(ignorevalues) do reverseignore[value]=i end
	-- do the ones with short names first
	local reverseshorts = {}
	for name,short in pairs(short_names) do
		reverseshorts[short] = name
	end
	for name,value in pairs(values.value) do
		name = name:gsub(".*%.", "")	-- remove the "0." from the front
		if (short_names[name] or reverseshorts[name]) and value.value and value.value ~= "" then
			name = short_names[name] or name
			-- escape characters
			outstr[#outstr + 1] = name .. "=" .. format.escapespecialcharacters(value.value):gsub("[=]", "\\%1")
		end
	end
	-- now do the ones with no short names (and not ignored)
	for name,value in pairs(values.value) do
		name = name:gsub(".*%.", "")	-- remove the "0." from the front
		if not reverseignore[name] and not short_names[name] and not reverseshorts[name] and value.value and value.value ~= "" then
			-- escape characters
			outstr[#outstr + 1] = format.escapespecialcharacters(name) .. "=" .. format.escapespecialcharacters(value.value):gsub("[=]", "\\%1")
		end
	end
	return "/"..table.concat(outstr, "/")
end

local getconfigentry = function(section, value)
	config = config or format.parse_ini_file(fs.read_file(basedir..configfile) or "")
	local result = config[section][value] or config[""][value] or ""
	while string.find(result, "%$[%w_]+") do
		local sub = string.match(result, "%$[%w_]+")
		result = string.gsub(result, sub, config[section][string.sub(sub,2)] or config[""][string.sub(sub,2)] or "")
	end
	return result
end

-- Find the sections of the config file that define ca's (ca -name option)
local find_ca_sections = function()
	config = config or format.parse_ini_file(fs.read_file(basedir..configfile) or "")
	local cert_types = {}

	for section in pairs(config) do
		local success = true
		for i,entry in ipairs(ca_mandatory_entries) do
			if getconfigentry(section,entry) == "" then
				success = false
				break
			end
		end
		if success then
			cert_types[#cert_types + 1] = section
		end
	end

	return cert_types
end

local validate_request = function(defaults, noextensionsections)
	local success
	success, defaults = validate_distinguished_names(defaults)

	if defaults.value.certtype then
		local foundcert=false
		for i,cert in ipairs(defaults.value.certtype.option) do
			if defaults.value.certtype.value == cert then
				foundcert=true
				break
			end
		end
		if not foundcert then
			success = false
			defaults.value.certtype.errtxt = "Invalid certificate type"
		end
	end

	if defaults.value.extensions then
		config = config or format.parse_ini_file(fs.read_file(basedir..configfile) or "")
		local extensions = format.parse_ini_file(defaults.value.extensions.value)
		for name,value in pairs(extensions or {}) do
			if name ~= "" and noextensionsections then
				defaults.value.extensions.errtxt = "Cannot contain sections"
				success = false
			elseif name ~= "" and config[name] then
				defaults.value.extensions.errtxt = "Duplicate section name"
				success = false
			end
		end
	end

	return success, defaults
end

local copyca = function(cacert, cakey)
	config = config or format.parse_ini_file(fs.read_file(basedir..configfile) or "")
	local certpath = getconfigentry(config.ca.default_ca, "certificate")
	fs.move_file(cacert, certpath)
	local keypath = getconfigentry(config.ca.default_ca, "private_key")
	fs.move_file(cakey, keypath)
end

local checkdir = function(name, dirpath)
	local errtxt, cmdline
	local filestats = posix.stat(dirpath, "type")
	if not filestats or filestats == "" then
		errtxt = name.." does not exist"
		cmdline = function() fs.create_directory(dirpath) end
	elseif filestats ~= "directory" then
		errtxt = "UNRECOVERABLE - "..name.." not a directory"
	end
	return errtxt, cmdline
end

local checkfile = function(name, filepath, default)
	local errtxt, cmdline
	local filestats = posix.stat(filepath, "type")
	if not filestats or filestats == "" then
		errtxt = name.." does not exist"
		if default then
			cmdline = function() fs.write_file(filepath, default) end
		else
			cmdline = function() fs.create_file(filepath) end
		end
	elseif filestats ~= "regular" then
		errtxt = "UNRECOVERABLE - "..name.." not a file"
	end
	return errtxt, cmdline
end

local hashname = function(name)
	local hash = {name:byte(1,-1)}
	-- no longer returning '-' separated decimal, but 2 char hex
	--return table.concat(hash, "-")
	for i,val in ipairs(hash) do hash[i] = string.format("%02X", val) end
	return table.concat(hash)
end

local unhashname = function(hashstring)
	local hash = {}
	-- this is to be backward compatible with '-' separated decimal
	if string.find(hashstring, "-") then
		for char in string.gmatch(hashstring, "([^-]+)-*") do
			hash[#hash+1] = char
		end
	else
		for char in string.gmatch(hashstring, "%x%x") do
			hash[#hash+1] = tonumber(char, 16)
		end
	end
	return string.char(unpack(hash))
end

local listrequests = function(user)
	user = user or "*"
	local list={}
	local files = posix.glob(basedir..requestdir..user..".*\\.csr") or {}
	for i,x in ipairs(files) do
		local name = string.gsub(posix.basename(x), ".csr$", "")
		local a,b,c = string.match(name, "([^%.]*)%.([^%.]*)%.([^%.]*)")
		list[#list + 1] = {request=name, user=a, certtype=b, commonName=unhashname(c)}
	end
	return cfe({ type="list", value=list, label="List of pending requests" })
end

local listcerts = function(user)
	user = user or "*"
	local list={}
	local files = posix.glob(basedir..certdir..user..".*\\.pfx") or {}
	-- Do this in two steps - saves forking openssl for each cert, which
	-- speeds things up noticably for > 100 certs
	local crtlist = {}
	for i,x in ipairs(files) do
		local name = string.gsub(posix.basename(x), ".pfx$", "")
		local a,b,c,d = string.match(name, 
			"([^%.]*)%.([^%.]*)%.([^%.]*).([^%.]*)")
		list[#list + 1] = {cert=name, user=a, certtype=b, 
			commonName=unhashname(c), serial=d, enddate=enddate, 
			daysremaining=time}
		crtlist[#crtlist+1] = "x509 -in "..basedir..certdir..name..".crt -noout -enddate"
	end

	local out = modelfunctions.run_executable({"openssl"}, false, table.concat(crtlist, "\n").."\nexit\n")
	local outtab = format.string_to_table(out, "\n")

	for i,x in ipairs(files) do
		local enddate = string.match(outtab[i] or "", "notAfter=(.*)") or "Jan 1 00:00:01 1970 GMT"
		local month, day, year = 
			string.match(enddate, "(%a+)%s+(%d+)%s+%S+%s+(%d+)")
		
		local reversemonth = {Jan=1,Feb=2,Mar=3,Apr=4,May=5,Jun=6,
					Jul=7,Aug=8,Sep=9,Oct=10,Nov=11,Dec=12}
		local time = os.time({year=year, month=reversemonth[month], day=day})
		if os.time() > time then
			time = 0
		else
			time = (time-os.time())/86400
		end
		list[i].enddate = enddate
		list[i].daysremaining = time
	end

	return cfe({ type="list", value=list, label="List of approved certificates" })
end

local listrevoked = function()
	config = config or format.parse_ini_file(fs.read_file(basedir..configfile) or "")
	local databasepath = getconfigentry(config.ca.default_ca, "database")
	local revoked = {}
	local database = fs.read_file_as_array(databasepath) or {}
	for x,line in ipairs(database) do
		if string.sub(line,1,1) == "R" then
			revoked[#revoked + 1] = string.match(line, "^%S+%s+%S+%s+%S+%s+(%S+)")
		end
	end
	return cfe({ type="list", value=revoked, label="Revoked serial numbers" })
end

local checkenvironment = function()
	local errtxt = {}
	local cmdline = {}
	
	-- First check for the openssl, req, and cert directories
	errtxt[#errtxt+1], cmdline[#cmdline+1] = checkdir("openssl directory", basedir)
	errtxt[#errtxt+1], cmdline[#cmdline+1] = checkdir("new certificate directory", basedir..certdir)
	errtxt[#errtxt+1], cmdline[#cmdline+1] = checkdir("request directory", basedir..requestdir)

	-- Then check for the config file entries
	config = config or format.parse_ini_file(fs.read_file(basedir..configfile) or "")

	if config then
		local chkpath = getconfigentry(config.ca.default_ca, "new_certs_dir")
		errtxt[#errtxt+1], cmdline[#cmdline+1] = checkdir("new_certs_dir", chkpath)

		local file = getconfigentry(config.ca.default_ca, "certificate")
		chkpath = posix.dirname(file)
		errtxt[#errtxt+1], cmdline[#cmdline+1] = checkdir("certificate directory", chkpath)
	
		file = getconfigentry(config.ca.default_ca, "private_key")
		chkpath = posix.dirname(file)
		errtxt[#errtxt+1], cmdline[#cmdline+1] = checkdir("private_key directory", chkpath)
	
		file = getconfigentry(config.ca.default_ca, "database")
		chkpath = posix.dirname(file)
		errtxt[#errtxt+1], cmdline[#cmdline+1] = checkdir("database directory", chkpath)
		errtxt[#errtxt+1], cmdline[#cmdline+1] = checkfile("database", file)
	
		file = getconfigentry(config.ca.default_ca, "serial")
		chkpath = posix.dirname(file)
		errtxt[#errtxt+1], cmdline[#cmdline+1] = checkdir("serial directory", chkpath)
		errtxt[#errtxt+1], cmdline[#cmdline+1] = checkfile("serial", file, "01")

		file = getconfigentry(config.ca.default_ca, "crlnumber")
		if file ~= "" then
			chkpath = posix.dirname(file)
			errtxt[#errtxt+1], cmdline[#cmdline+1] = checkdir("crlnumber directory", chkpath)
			errtxt[#errtxt+1], cmdline[#cmdline+1] = checkfile("crlnumber", file, "01")
		end
	else
		errtxt[#errtxt+1] = "Configuration invalid"
	end

	errtxt = table.concat(errtxt, '\n')
	local value
	if errtxt == "" then
		errtxt = nil
		value = "Environment ready"
	else
		value = "Environment not ready"
	end
	return cfe({ value=value, errtxt=errtxt, cmdline=cmdline, label="Environment" })
end

mymodule.getstatus = function(self, clientdata)
	-- set the working directory and umask once for model
	posix.umask("rw-------")
	posix.chdir(basedir)
	local retval = initializecfe(self, clientdata, "OpenSSL status")
	local value,errtxt=processinfo.package_version(packagename)
	retval.value.version = cfe({ value=value, errtxt=errtxt, label="Program version", name=packagename })
	retval.value.conffile = cfe({ value=basedir..configfile, label="Configuration file" })
	retval.value.cacert = cfe({ label="CA Certificate" })
	retval.value.cacertcontents = cfe({ type="longtext", label="CA Certificate contents" })
	retval.value.cakey = cfe({ label="CA Key" })
	if not fs.is_file(basedir..configfile) then
		retval.value.conffile.errtxt="File not found"
		retval.value.cacert.errtxt="File not defined"
		retval.value.cacertcontents.errtxt=""
		retval.value.cakey.errtxt="File not defined"
	else
		config = config or format.parse_ini_file(fs.read_file(basedir..configfile) or "")
		if (not config) or (not config.ca) or (not config.ca.default_ca) then
			retval.value.conffile.errtxt="Invalid config file"
			retval.value.cacert.errtxt="File not defined"
			retval.value.cacertcontents.errtxt=""
			retval.value.cakey.errtxt="File not defined"
		else
			retval.value.cacert.value = getconfigentry(config.ca.default_ca, "certificate")
			if not fs.is_file(retval.value.cacert.value) then
				retval.value.cacert.errtxt="File not found"
			else
				retval.value.cacertcontents.value, retval.value.cacertcontents.errtxt = modelfunctions.run_executable({"openssl", "x509", "-in", retval.value.cacert.value, "-noout", "-text"})
				local enddate = string.match(retval.value.cacertcontents.value, "Not After : (.*)")
				local month, day, year = string.match(enddate, "(%a+)%s+(%d+)%s+%S+%s+(%d+)")

				local reversemonth = {Jan=1,Feb=2,Mar=3,Apr=4,May=5,Jun=6,Jul=7,Aug=8,Sep=9,Oct=10,Nov=11,Dec=12}
				local time = os.time({year=year, month=reversemonth[month], day=day})
				if os.time() > time then
					time = 0
					retval.value.cacert.errtxt="Certificate expired"
				else
					time = (time-os.time())/86400
				end
				retval.value.cacert.daysremaining=time
			end
			retval.value.cakey.value = getconfigentry(config.ca.default_ca, "private_key")
			if not fs.is_file(retval.value.cakey.value) then
				retval.value.cakey.errtxt="File not found"
			end
		end
	end
	retval.value.environment = checkenvironment()
	return retval
end

mymodule.getreqdefaults = function(self, clientdata)
	local defaults = getdefaults(self, clientdata)

	--Add in the encryption bit default
	local encryption = config.req.default_bits
	defaults.value.encryption = cfe({ type="select", label="Encryption Bits", value=encryption, option={"2048", "4096"}, seq=94 })
	
	-- Add in the default days
	local validdays = getconfigentry(config.ca.default_ca, "default_days")
	defaults.value.validdays = cfe({ type="text", label="Period of Validity (Days)", value=validdays, descr="Number of days this certificate is valid for", seq=95 })
	
	-- Add in the ca type default
	defaults.value.certtype = cfe({ type="select", label="Certificate Type", 
		value=config.ca.default_ca, option=find_ca_sections(), seq=96 })
	-- Add in the extensions
	local extensions = ""
	local content = fs.read_file(basedir..configfile) or ""
	config = config or format.parse_ini_file(content)
	if config.req.req_extensions then
		extensions = format.get_ini_section(content, config.req.req_extensions)
	end
	defaults.value.extensions = cfe({ type="longtext", label="Additional x509 Extensions", value=extensions, descr="These extensions can be overridden by the Certificate Type", seq=97 })
	
	return defaults
end

mymodule.setreqdefaults = function(self, defaults)
	local success, defaults = validate_request(defaults, true)

	-- If success, write the values to the config file
	if success then
		local fileval = fs.read_file(basedir..configfile) or ""
		config = config or format.parse_ini_file(fileval)
		local ext_section
		if not config.req or not config.req.req_extensions then
			ext_section = "v3_req"
			while config[ext_section] do ext_section = "v3_req_"..tostring(os.time()) end
			fileval = format.update_ini_file(fileval, "req", "req_extensions", ext_section)
		else
			ext_section = config.req.req_extensions
		end
		config = nil
		fileval = format.update_ini_file(fileval,"","default_days",defaults.value.validdays.value)
		fileval = format.set_ini_section(fileval, ext_section, format.dostounix(defaults.value.extensions.value))
		fileval = format.update_ini_file(fileval, "ca", "default_ca", defaults.value.certtype.value)
		fileval = write_distinguished_names(fileval, defaults, {"certtype", "extensions", "validdays"})
		fs.write_file(basedir..configfile, fileval)
	end

	if not success then
		defaults.errtxt = "Failed to set defaults"
	end

	return defaults
end

mymodule.getnewrequest = function(self, clientdata)
	local values = mymodule.getreqdefaults(self, clientdata)
	-- In addition to the request defaults, we need a password and confirmation
	values.value.password = cfe({ type="password", label="Password", seq=98 })
	values.value.password_confirm = cfe({ type="password", label="Password confirmation", seq=99 })
	return values
end

mymodule.submitrequest = function(self, defaults, submit, user)
	local success, defaults = validate_request(defaults)

	-- Must have a common name
	if #defaults.value.commonName.value == 0 then
		defaults.value.commonName.errtxt = "Common Name cannot be blank"
		success = false
	end
	-- Check validity of password
	if #defaults.value.password.value < 4 then
		defaults.value.password.errtxt = "Password too short"
		success = false
	end
	if defaults.value.password.value ~= defaults.value.password_confirm.value then
		defaults.value.password_confirm.errtxt = "You entered wrong password/confirmation"
		success = false
	end

	local reqname = basedir..requestdir..user.."."..defaults.value.certtype.value.."."..hashname(defaults.value.commonName.value)
	if fs.is_file(reqname..".csr") then
		defaults.errtxt = "Failed to submit request\nRequest already exists"
		success = false
	end
	
	if not tonumber(defaults.value.validdays.value) then
		defaults.value.validdays.errtxt = "Period of Validity is not a number"
		success = false
	end

	if success then
		-- Submit the request
		local subject = create_subject_string(defaults, {"password", "password_confirm", "certtype", "extensions"})

		-- Generate a temp config file for this request
		local fileval = fs.read_file(basedir..configfile) or ""
		config = config or format.parse_ini_file(fileval)
		local ext_section = "v3_req"
		while config[ext_section] do ext_section = "v3_req_"..tostring(os.time()) end
		local content = format.dostounix(defaults.value.extensions.value)
		-- Override with the extensions for this cert type
		if config[defaults.value.certtype.value].x509_extensions then
			local temp = config[defaults.value.certtype.value].x509_extensions
			for name,value in pairs(config[temp] or {}) do
				if not string.find(value, "issuer") then
					content = format.update_ini_file(content, "", name, value)
				end
			end
		end
	
		fileval = format.update_ini_file(fileval, "req","default_bits",defaults.value.encryption.value)
		fileval = format.update_ini_file(fileval, "","default_days",defaults.value.validdays.value)	
		fileval = format.set_ini_section(fileval, ext_section, content)
		fileval = format.update_ini_file(fileval, "req", "req_extensions", ext_section)
		fs.write_file(reqname..".cfg", fileval)
		
		defaults.descr, defaults.errtxt = modelfunctions.run_executable({"openssl", "req", "-nodes", "-new", "-config", reqname..".cfg", "-keyout", reqname..".pem", "-out", reqname..".csr", "-subj", subject}, true)
		local certfilestats = posix.stat(reqname..".csr")
		local keyfilestats = posix.stat(reqname..".pem")
		if not certfilestats or certfilestats.size == 0 or not keyfilestats or keyfilestats.size == 0 then
			success = false
			os.remove(reqname..".cfg")
			os.remove(reqname..".csr")
			os.remove(reqname..".pem")
		else
			fs.write_file(reqname..".pwd", defaults.value.password.value)
			fs.write_file(reqname..".sbj", subject)
		end
	end

	if not success and not defaults.errtxt then
		defaults.errtxt = "Failed to submit request"
	end

	return defaults
end

mymodule.readall = function(self, clientdata)
	local result = initializecfe(self, clientdata, "All Certificates")
	result.value.pending = listrequests()
	result.value.approved = listcerts()
	result.value.revoked = listrevoked()
	return result
end

mymodule.readuser = function(self, clientdata, user)
	local result = initializecfe(self, clientdata, "Certificates for "..user)
	result.value.user = cfe({ value=user, label="User Name" })
	result.value.pending = listrequests(user)
	result.value.approved = listcerts(user)
	result.value.revoked = listrevoked()
	return result
end

mymodule.viewrequest = function(self, clientdata)
	local retval = initializecfe(self, clientdata, "Request")
	retval.value.request = cfe({ label="Request", key=true })
        self.handle_clientdata(retval, clientdata)

	local request = retval.value.request.value
	local reqpath = basedir..requestdir .. request
	local cmdresult = modelfunctions.run_executable({"openssl", "req", "-in", reqpath..".csr", "-text", "-noout"})
	local a,b,c = string.match(request, "([^%.]*)%.([^%.]*)%.([^%.]*)")
	retval.value.details = cfe({ type="structure", value={request=request, user=a, certtype=b, commonName=unhashname(c), value=cmdresult}, label="Request Details" })
	return retval
end

mymodule.getapproverequest = function(self, clientdata)
	local retval = initializecfe(self, clientdata, "Approve Request")
	retval.value.request = cfe({ value=clientdata.request or "", label="Request" })
	return retval
end

mymodule.approverequest = function(self, apprequest)
	local reqpath = basedir..requestdir .. apprequest.value.request.value
	if fs.is_file(reqpath..".csr") then
		-- Request file exists, so try to sign
		local user,certtype,commonName = string.match(apprequest.value.request.value, "([^%.]*)%.([^%.]*)%.([^%.]*)")

		-- Add the serial number to the end of the cert file name
		local serialpath = getconfigentry(certtype, "serial")
		local serialfile = fs.read_file(serialpath) or ""
		local serial = string.match(serialfile, "%x+")
		local certname = basedir..certdir..apprequest.value.request.value.."."..serial
		
		-- Now, sign the certificate
		apprequest.descr, apprequest.errtxt = modelfunctions.run_executable({"openssl", "ca", "-config", reqpath..".cfg", "-in", reqpath..".csr", "-out", certname..".crt", "-name", certtype, "-batch"}, true)

		-- If certificate created, create the wrapped up pkcs12
		local filestats = posix.stat(certname..".crt")
		if filestats and filestats.size > 0 then
			-- We're wrapping up the key, the cert, and the CA cert (and whatever came with it)
			local newcmdresult, newerrtxt = modelfunctions.run_executable({"openssl", "pkcs12", "-export", "-inkey", reqpath..".pem", "-in", certname..".crt", "-out", certname..".pfx", "-passout", "file:"..reqpath..".pwd", "-certfile", getconfigentry(certtype, "certificate")}, true)
			apprequest.descr = apprequest.descr .. newcmdresult
			if apprequest.errtxt then
				apprequest.errtxt = apprequest.errtxt .. (newerrtxt or "")
			else
				apprequest.errtxt = newerrtxt
			end
		end

		-- Finally, remove the request
		filestats = posix.stat(certname..".pfx")
		if filestats and filestats.size > 0 then
			fs.move_file(reqpath..".pwd", certname..".pwd")
			fs.move_file(reqpath..".sbj", certname..".sbj")
			fs.move_file(reqpath..".pem", certname..".pem")
			fs.move_file(reqpath..".cfg", certname..".cfg")
			os.remove(reqpath..".csr")
		else
			-- or failed, remove the cert
			os.remove(certname..".crt")
			os.remove(certname..".pfx")
		end
	else
		apprequest.errtxt = "Failed to approve request"
		apprequest.value.request.errtxt = "Failed to find request"
	end
	return apprequest
end

mymodule.getdeleterequest = function(self, clientdata)
	local retval = initializecfe(self, clientdata, "Delete Request")
	retval.value.request = cfe({ value=clientdata.request or "", label="Request" })
	return retval
end

mymodule.deleterequest = function(self, delrequest, submit, user)
	user = user or ".*"
	if (not fs.is_file(basedir..requestdir..delrequest.value.request.value..".csr")) or (not string.find(delrequest.value.request.value, "^"..user.."%.")) then
		delrequest.value.request.errtxt = "Request not found"
		delrequest.errtxt = "Failed to Delete Request"
	else
		local reqpath = basedir..requestdir..delrequest.value.request.value
		os.remove(reqpath..".pwd")
		os.remove(reqpath..".sbj")
		os.remove(reqpath..".pem")
		os.remove(reqpath..".cfg")
		os.remove(reqpath..".csr")
	end
	return delrequest
end

mymodule.viewcert = function(self, clientdata)
	local retval = initializecfe(self, clientdata, "Certificate")
	retval.value.cert = cfe({ label="Certificate", key=true })
        self.handle_clientdata(retval, clientdata)

	local cert = retval.value.cert.value
	local cmdresult = modelfunctions.run_executable({"openssl", "x509", "-in", basedir..certdir..cert..".crt", "-noout", "-text"})
	local a,b,c,d = string.match(cert, "([^%.]*)%.([^%.]*)%.([^%.]*).([^%.]*)")
	retval.value.details = cfe({ type="structure", value={cert=cert, user=a, certtype=b, commonName=unhashname(c), serial=d, value=cmdresult}, label="Certificate Details" })
	return retval
end

mymodule.getcert = function(self, clientdata)
	local retval = initializecfe(self, clientdata, "Certificate")
	retval.value.cert = cfe({ label="Certificate", key=true })
	self.handle_clientdata(retval, clientdata)

	local cert = retval.value.cert.value
	if cert ~= "" then
		local f = fs.read_file(basedir..certdir..cert..".pfx") or ""
		local a,b,c,d = string.match(cert, "([^%.]*)%.([^%.]*)%.([^%.]*).([^%.]*)")
		c = string.gsub(unhashname(c), "[^%w_-]", "")
		retval.value.details = cfe({ type="raw", value=f, label=c..".pfx", option="application/x-pkcs12" })
	end

	return retval
end

mymodule.getrevokecert = function(self, clientdata)
	local retval = initializecfe(self, clientdata, "Revoke Certificate")
	retval.value.cert = cfe({ value=clientdata.cert or "", label="Certificate" })
	return retval
end

mymodule.revokecert = function(self, revreq)
	revreq.descr, revreq.errtxt = modelfunctions.run_executable({"openssl", "ca", "-config", basedir..configfile, "-revoke", basedir..certdir..revreq.value.cert.value..".crt", "-batch"}, true)
	return revreq
end

mymodule.getdeletecert = function(self, clientdata)
	local retval = initializecfe(self, clientdata, "Delete Certificate")
	retval.value.cert = cfe({ value=clientdata.cert or "", label="Certificate" })
	return retval
end

mymodule.deletecert = function(self, delcert)
	-- The certificate will still be in the ca directories and index.txt, just not available for web interface
	local certname = basedir..certdir..delcert.value.cert.value
	os.remove(certname..".cfg")
	os.remove(certname..".crt")
	os.remove(certname..".pem")
	os.remove(certname..".pfx")
	os.remove(certname..".pwd")
	os.remove(certname..".sbj")
	return delcert
end

mymodule.getrenewcert = function(self, clientdata)
	local retval = initializecfe(self, clientdata, "Renew Certificate")
	retval.value.cert = cfe({ value=clientdata.cert or "", label="Certificate" })
	return retval
end

mymodule.renewcert = function(self, recert, submit, approve)
	local success = true
	local user,certtype,commonName,serialnum = string.match(recert.value.cert.value, "([^%.]*)%.([^%.]*)%.([^%.]*).([^%.]*)")
	local reqname = basedir..requestdir..user.."."..certtype.."."..commonName
	if fs.is_file(reqname..".csr") then
		recert.errtxt = "Failed to submit request"
		recert.value.cert.errtxt = "Request already exists"
		success = false
	end

	if success then
		-- Submit the request
		-- First, put the subject, config file and password in place
		local certname = basedir..certdir..recert.value.cert.value
		fs.copy_file(certname..".pwd", reqname..".pwd")
		fs.copy_file(certname..".sbj", reqname..".sbj")
		fs.copy_file(certname..".cfg", reqname..".cfg")

		-- Next, get the subject (removing the /n inserted by fs.write_file)
		local subject = string.gsub(fs.read_file(reqname..".sbj") or "", "\n", "")

		-- Next, submit the request (new key)
		recert.descr, recert.errtxt = modelfunctions.run_executable({"openssl", "req", "-nodes", "-new", "-config", reqname..".cfg", "-keyout", reqname..".pem", "-out", reqname..".csr", "-subj", subject}, true)
		local filestats = posix.stat(reqname..".csr")
		if not filestats or filestats.size == 0 then
			recert.errtxt = "Failed to submit request\n"..recert.descr
			recert.descr = nil
			success = false
			os.remove(reqname..".pwd")
			os.remove(reqname..".sbj")
			os.remove(reqname..".cfg")
			os.remove(reqname..".pem")
			os.remove(reqname..".csr")
		else
			recert.descr = "Submitted request"
		end
	end

	if success and approve then
		local tmp = mymodule.getapproverequest(self, {})
		tmp.value.request.value = posix.basename(reqname)
		tmp = mymodule.approverequest(self, tmp)
		if tmp.errtxt then
			recert.descr = recert.descr.."\n"..tmp.errtxt
		end
	end

	return recert
end

mymodule.getcrl = function(self, clientdata)
	local retval = initializecfe(self, clientdata, "Certificate Revocation List")
	retval.value.crltype = cfe({ type="select", value="", option={"", "DER", "PEM"}, label="CRL Type", key=true })
	self.handle_clientdata(retval, clientdata)

	local crltype = retval.value.crltype.value
	if modelfunctions.validateselect(retval.value.crltype) then
		retval.value.details = cfe({ type="raw", option="application/pkix-crl" })
		modelfunctions.run_executable({"openssl", "ca", "-config", basedir..configfile, "-gencrl", "-out", basedir.."ca-crl.crl"})
		modelfunctions.run_executable({"openssl", "crl", "-in", basedir.."ca-crl.crl", "-out", basedir.."ca-der-crl.crl", "-outform", "DER"})
		if crltype == "DER" then
			retval.value.details.label = "ca-der-crl.crl"
			retval.value.details.value = fs.read_file(retval.value.details.label) or ""
		elseif crltype == "PEM" then
			retval.value.details.label = "ca-crl.crl"
			retval.value.details.value = fs.read_file(retval.value.details.label) or ""
		else
			retval.value.details.value = fs.read_file("ca-der-crl.crl") or ""
		end
	end

	return retval
end

mymodule.getca = function(self, clientdata)
	local retval = initializecfe(self, clientdata, "CA Certificate")
	retval.value.certtype = cfe({ type="select", value="", option={"", "DER", "PEM"}, label="Certificate Type", key=true })
	self.handle_clientdata(retval, clientdata)

	local certtype = retval.value.certtype.value
	if modelfunctions.validateselect(retval.value.certtype) then
		retval.value.details = cfe({ type="raw", option="application/x-x509-ca-cert" })
		local fname = "cacert."
		if certtype == "DER" then
			if not posix.stat(basedir.."cacert.der") then
				modelfunctions.run_executable({"openssl", "x509", "-in", basedir.."cacert.pem", "-outform", "der", "-out", basedir.."cacert.der"})
			end
			fname = fname.."der"
			retval.value.details.label = fname
		elseif certtype == "PEM" then
			fname = fname.."pem"
			retval.value.details.label = fname
		else
			fname = fname.."pem"
		end
		retval.value.details.value = fs.read_file(fname) or ""
	end

	return retval
end

mymodule.getnewputca = function(self, clientdata)
	local retval = initializecfe(self, clientdata, "Upload CA Certificate")
	retval.value.ca = cfe({ type="raw", value=0, label="CA Certificate", descr='File must be a password protected ".pfx" file', seq=1 })
	retval.value.password = cfe({ type="password", label="Certificate Password", seq=2 })
	return retval
end

mymodule.putca = function(self, newca)
	local success = true
	-- Trying to upload a cert/key
	-- The way haserl works, ca contains the temporary file name
	-- First, get the cert
	local cmd, f, cmdresult
	if validator.is_valid_filename(newca.value.ca.value, "/tmp/") and fs.is_file(newca.value.ca.value) then
		cmdresult = modelfunctions.run_executable({"openssl", "pkcs12", "-in", newca.value.ca.value, "-out", newca.value.ca.value.."cert.pem", "-password", "pass:"..newca.value.password.value, "-nokeys"}, true)
		local filestats = posix.stat(newca.value.ca.value.."cert.pem")
		if not filestats or filestats.size == 0 then
			newca.value.ca.errtxt = "Could not open certificate\n"..cmdresult
			success = false
		end
	else
		newca.value.ca.errtxt = "Invalid certificate"
		success = false
	end

	-- Check to make sure we got a CA cert
	if success then
		cmdresult = modelfunctions.run_executable({"openssl", "x509", "-in", newca.value.ca.value.."cert.pem", "-noout","-text"})
		if not string.find(cmdresult, "CA:TRUE") then
			newca.value.ca.errtxt = "Could not find CA Certificate"
			success = false
		end
	end
		
	-- Now, get the key
	if success then
		cmdresult = modelfunctions.run_executable({"openssl", "pkcs12", "-in", newca.value.ca.value, "-out", newca.value.ca.value.."key.pem", "-password", "pass:"..newca.value.password.value, "-nocerts", "-nodes"}, true)
		filestats = posix.stat(newca.value.ca.value.."key.pem")
		if not filestats or filestats.size == 0 then
			newca.value.ca.errtxt = "Could not find CA key\n"..cmdresult
			success = false
		end
	end

	if success then
		-- copy the keys
		copyca(newca.value.ca.value.."cert.pem", newca.value.ca.value.."key.pem")
	else
		newca.errtxt = "Failed to upload CA certificate"
	end

	-- Delete the temporary files
	if validator.is_valid_filename(newca.value.ca.value, "/tmp/") and fs.is_file(newca.value.ca.value) then
		os.remove(newca.value.ca.value.."cert.pem")
		os.remove(newca.value.ca.value.."key.pem")
	end

	-- Clear the values
	newca.value.ca.value = ""
	newca.value.password.value = ""

	return newca
end

mymodule.getnewcarequest = function(self, clientdata)
	request = getdefaults(self, clientdata)
	-- In addition to the distinguished name defaults, we need days
	request.value.days = cfe({ value="365", label="Number of days to certify", seq=95 })
	return request
end

mymodule.generateca = function(self, defaults)
	local success, defaults = validate_request(defaults)

	if not validator.is_integer(defaults.value.days.value) then
		defaults.value.days.errtxt = "Must be a number"
		success = false
	end

	if success then
		os.remove("/tmp/cacert.pem")
		os.remove("/tmp/cakey.pem")

		-- Submit the request
		local subject = create_subject_string(defaults, {"days"})
		local cmdresult = modelfunctions.run_executable({"openssl", "req", "-x509", "-nodes", "-new", "-config", basedir..configfile, "-keyout", "/tmp/cakey.pem", "-out", "/tmp/cacert.pem", "-subj", subject, "-days", defaults.value.days.value}, true)
		local certfilestats = posix.stat("/tmp/cacert.pem")
		local keyfilestats = posix.stat("/tmp/cakey.pem")
		if not certfilestats or certfilestats.size == 0 or not keyfilestats or keyfilestats.size == 0 then
			defaults.errtxt = "Failed to generate CA certificate\n"..cmdresult
			success = false
		end

		if success then
			-- copy the keys
			copyca("/tmp/cacert.pem", "/tmp/cakey.pem")
		end

		-- Delete the temporary files
		os.remove("/tmp/cacert.pem")
		os.remove("/tmp/cakey.pem")
	end

	if not success and not defaults.errtxt then
		defaults.errtxt = "Failed to generate CA certificate"
	end

	return defaults
end

mymodule.getconfigfile = function(self, clientdata)
	local retval = initializecfe(self, clientdata, "")
	local retval2 = modelfunctions.getfiledetails(basedir..configfile)
	for name,value in pairs(retval.value) do
		retval2.value[name] = value
	end
	return retval2
end

mymodule.setconfigfile = function(self, filedetails)
	-- validate
	-- setfiledetails does not return the same cfe, so have to copy any missing ones
	local retval2 = modelfunctions.setfiledetails(self, filedetails, {basedir..configfile})
	for name,value in pairs(filedetails.value) do
		retval2.value[name] = value
	end
	return retval2
end

mymodule.getenvironment = function(self, clientdata)
	local retval = initializecfe(self, clientdata, "Check Environment")
	retval.value.status = checkenvironment()
	return retval
end

mymodule.setenvironment = function(self, setenv)
	-- loop through the cmdline and execute
	for x,cmd in ipairs(setenv.value.status.cmdline) do
		cmd()
	end
	setenv.value.status = checkenvironment()
	if setenv.value.status.errtxt then
		setenv.errtxt = "Failed to Configure Environment"
	end
	return setenv
end

mymodule.get_ca_chain = function(self, clientdata)
	-- determine the CommonNames for each CA in the chain from cadir back to openssldir
	local retval = initializecfe(self, clientdata, "CA Chain Information")
	retval.value.commonnames = cfe({ type="list", value={}, label="CA Common Names" })
	local cadir,count = string.gsub(retval.value.cadir.value, "/", "/")
	if retval.value.cadir.value == "" then count=-1 end
	local matchstring = ""
	for i=1, (count+2) do
		local basedir = openssldir
		if matchstring ~= "" then
			basedir = basedir..string.match(cadir, matchstring).."/"
		end
		matchstring = matchstring.."/?[^/]*"
		-- This messes with the global, but it will be correct again at the end of the loop
		config = format.parse_ini_file(fs.read_file(basedir..configfile) or "")
		if (not config) or (not config.ca) or (not config.ca.default_ca) then
			--error "Invalid config"
			retval.value.commonnames.value[i] = "error"
		else
			local cacert = getconfigentry(config.ca.default_ca, "certificate")
			if not fs.is_file(cacert) then
				--error "File not found"
				retval.value.commonnames.value[i] = "error"
			else
				cacertsubject, errtxt = modelfunctions.run_executable({"openssl", "x509", "-in", cacert, "-noout", "-subject"})
				if errtxt or not string.find(cacertsubject, "CN=") then
					--error "CommonName not found"
					retval.value.commonnames.value[i] = "error"
				else
					retval.value.commonnames.value[i] = string.match(cacertsubject, "CN=([^/%W]*)")
				end
			end
		end
	end

	return retval
end

mymodule.getsubca = function(self, clientdata)
	local retval = initializecfe(self, clientdata, "Sub-CA Certificate")
	retval.value.cert = cfe({ label="Certificate", key=true })
	return retval
end

mymodule.createsubca = function(self, subca)
	local success = true
	local cert = basedir..certdir..subca.value.cert.value
	if not posix.stat(cert..".crt") or not string.match(subca.value.cert.value, "[^%.]*%.ssl_ca_cert%.") then
		subca.value.cert.errtxt = "Invalid Sub-CA"
		success = false
	else
		local subcadir = basedir..subca.value.cert.value.."/"
		if not fs.is_dir(subcadir) then
			success = fs.create_directory(subcadir)
		end
		if success and not posix.stat(subcadir..configfile) then
			-- Copy the config from this CA, but modify 'dir'
			local configcontent = fs.read_file(basedir..configfile) or ""
			configcontent = format.update_ini_file(configcontent, nil, "dir", basedir..subca.value.cert.value)
			fs.write_file(subcadir..configfile, configcontent)

			-- Copy the cert
			-- temporarily overwrite the global config with the new one
			config = format.parse_ini_file(configcontent)
			fs.copy_file(cert..".crt", getconfigentry(config.ca.default_ca, "certificate"))
			fs.copy_file(cert..".pem", getconfigentry(config.ca.default_ca, "private_key"))
			config = nil

			-- Set up the environment
			-- temporarily overwrite the basedir
			local oldbasedir = basedir
			basedir = subcadir
			local envstatus = checkenvironment()
			-- loop through the cmdline and execute
			for x,cmd in ipairs(envstatus.cmdline) do
				cmd()
			end
			basedir = oldbasedir
		end
		if success and self.sessiondata then
			self.sessiondata.openssl_cadir = subca.value.cadir.value.."/"..subca.value.cert.value
		end
	end
	if not success then
		subca.errtxt = "Failed to configure sub-CA"
	end
	return subca
end

return mymodule
