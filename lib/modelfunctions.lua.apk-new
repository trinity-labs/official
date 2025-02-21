local mymodule = {}

-- Load libraries
fs = require("acf.fs")
format = require("acf.format")
processinfo = require("acf.processinfo")
posix = require("posix")
subprocess = require("subprocess")

function mymodule.getenabled(servicename)
	local result = cfe({ label = "Program status", name=servicename })
	result.value, result.errtxt = processinfo.daemoncontrol(servicename, "status")
	if result.errtxt then
		result.value = ""
		result.errtxt = "Program not installed"
	else
		-- We only want the part that comes after status:
		result.value = string.gsub(result.value, "^.*%* status: ", "")
		result.value = string.gsub(result.value, "^%l", string.upper)
	end
	return result
end

function mymodule.get_startstop(servicename)
	local service = cfe({ hidden=true, value=servicename, label="Service Name" })
        local actions, descr = processinfo.daemon_actions(servicename)
	local errtxt
	if not actions then
		actions = {}
		errtxt = descr
	else
		for i,v in ipairs(actions) do
			actions[i] = v:gsub("^%l", string.upper)
		end
	end
	return cfe({ type="group", label="Management", value={servicename=service}, option=actions, errtxt=errtxt })
end

function mymodule.startstop_service(startstop, action)
	if not action then
		startstop.errtxt = "Invalid Action"
	else
		local reverseactions = {}
		for i,act in ipairs(startstop.option) do reverseactions[string.lower(act)] = i end
		if reverseactions[string.lower(action)] then
			local cmdresult, errtxt = processinfo.daemoncontrol(startstop.value.servicename.value, string.lower(action))
			startstop.descr = cmdresult
			startstop.errtxt = errtxt
		else
			startstop.errtxt = "Unknown command!"
		end
	end
	return startstop
end

function mymodule.getstatus(servicename, packagename, label)
	local status = {}

	if packagename then
		local value, errtxt = processinfo.package_version(packagename)
		status.version = cfe({
			label="Program version",
			value=value,
			errtxt=errtxt,
			name=packagename
			})
	end

	if servicename then
		status.status = mymodule.getenabled(servicename)

		local autostart_value, autostart_errtxt = processinfo.process_autostart(servicename)
		status.autostart = cfe({
			label="Autostart status",
			value=autostart_value,
			errtxt=autostart_errtxt,
			name=servicename
			})
	end

	return cfe({ type="group", value=status, label=label })
end

function mymodule.getfiledetails(file, validatefilename, validatefiledetails)
	local filename = cfe({ value=file or "", label="File name" })
	local filecontent = cfe({ type="longtext", label="File content" })
	local size = cfe({ value="0", label="File size" })
	local mtime = cfe({ value="---", label="File date" })
	local filedetails = cfe({ type="group", value={filename=filename, filecontent=filecontent, size=size, mtime=mtime}, label="Config file details" })
	local success = true
	if type(validatefilename) == "function" then
		success = validatefilename(filedetails.value.filename.value)
		if not success then
			filedetails.value.filename.errtxt = "Invalid File"
		end
	elseif type(validatefilename) == "table" then
		success = false
		filedetails.value.filename.errtxt = "Invalid File"
		for i,f in ipairs(validatefilename) do
			if f == filedetails.value.filename.value then
				success = true
				filedetails.value.filename.errtxt = nil
			end
		end
	end
	if success then
		if fs.is_file(file) then
			local filedetails = posix.stat(file)
			filecontent.value = fs.read_file(file) or ""
			size.value = format.formatfilesize(filedetails.size)
			mtime.value = format.formattime(filedetails.mtime)
		else
			filename.errtxt = "File not found"
		end
		if validatefiledetails then
			success, filedetails = validatefiledetails(filedetails)
		end
	end
	return filedetails
end

function mymodule.setfiledetails(self, filedetails, validatefilename, validatefiledetails)
	filedetails.value.filecontent.value = string.gsub(format.dostounix(filedetails.value.filecontent.value), "\n+$", "")
	local success = true
	if type(validatefilename) == "function" then
		success = validatefilename(filedetails.value.filename.value)
		if not success then
			filedetails.value.filename.errtxt = "Invalid File"
		end
	elseif type(validatefilename) == "table" then
		success = false
		filedetails.value.filename.errtxt = "Invalid File"
		for i,f in ipairs(validatefilename) do
			if f == filedetails.value.filename.value then
				success = true
				filedetails.value.filename.errtxt = nil
			end
		end
	end
	if success and type(validatefiledetails) == "function" then
		success, filedetails = validatefiledetails(filedetails)
	end
	if success then
		--fs.write_file(filedetails.value.filename.value, filedetails.value.filecontent.value)
		mymodule.write_file_with_audit(self, filedetails.value.filename.value, filedetails.value.filecontent.value)
		filedetails = mymodule.getfiledetails(filedetails.value.filename.value)
	else
		filedetails.errtxt = "Failed to set file"
	end

	return filedetails
end

function mymodule.validateselect(select)
	for i,option in ipairs(select.option) do
		if type(option) == "string" and option == select.value then
			return true
		elseif type(option.value) == "string" and option.value == select.value then
			return true
		elseif type(option.value) == "table" then
			for j,opt in ipairs(option.value) do
				if type(opt) == "string" and opt == select.value then
					return true
				elseif type(opt.value) == "string" and opt.value == select.value then
					return true
				end
			end
		end
	end
	select.errtxt = "Invalid selection"
	return false
end

function mymodule.validatemulti(multi)
	local reverseoption = {}
	for i,option in ipairs(multi.option) do
		if type(option) == "string" then
			reverseoption[option] = i
		elseif (type(option.value) == "string") then
			reverseoption[option.value] = i
		elseif (type(option.value) == "table") then
			for j,opt in ipairs(option.value) do
				if type(opt) == "string" then
					reverseoption[opt] = i
				elseif (type(opt.value) == "string") then
					reverseoption[opt.value] = i
				end
			end
		end
	end
	for i,value in ipairs(multi.value) do
		if not reverseoption[value] then
			multi.errtxt = "Invalid selection"
			return false
		end
	end
	return true
end

function mymodule.write_file_with_audit (self, path, str)
	if self then
		local pre = ""
		local post = ""

		local tmpfile = (self.conf.sessiondir or "/tmp/") ..
			(self.sessiondata.userinfo.userid or "unknown") .. "-" ..
			 os.time() .. ".tmp"

		if type(self.conf) == "table" then
			-- we make temporary globals for expand_bash_syntax_vars
			local a,b,c = TEMPFILE,CONFFILE,_G.self
			TEMPFILE=tmpfile
			CONFFILE=path
			_G.self=self

			pre = self.conf.audit_precommit or ""
			post = self.conf.audit_postcommit or ""

			local m = self.conf.app_hooks[self.conf.controller] or {}
			if m.audit_precommit then pre = m.audit_precommit end
			if m.audit_postcommit then post = m.audit_postcommit end
			m=nil

			if (type(pre) == "string") then
				pre = format.expand_bash_syntax_vars(pre)
			end
			if type (post) == "string" then
				post = format.expand_bash_syntax_vars(post)
			end
			TEMPFILE,CONFFILE,_G.self = a,b,c
		end

		fs.write_file(tmpfile,str)
		fs.copy_properties(path, tmpfile)

		if (type(pre) == "string" and #pre) then
			os.execute(pre)
		elseif (type(pre) == "function") then
			pre(self, path, tmpfile)
		end

		fs.move_file(tmpfile, path)

		if (type(post) == "string" and #post) then
			os.execute(post)
		elseif (type(post) == "function") then
			post(self, path, tmpfile)
		end
	else
		fs.write_file(path,str)
	end

	return
end

-- Run an executable and return the output and errtxt
-- args should be an array where args[1] is the executable
-- output will never be nil
-- errtxt will be nil for success and non-nil for failure
-- if include_err, then stderr will be prepended to stdout (if executable doesn't fail)
mymodule.run_executable = function(args, include_err, input)
	local output = ""
	local errtxt
       	local res, err = pcall(function()
		-- For security, set the path
		posix.setenv("PATH", "/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin")

		if input then
			args.stdin = subprocess.PIPE
		else
			args.stdin = "/dev/null"
		end
		args.stdout = subprocess.PIPE
		args.stderr = subprocess.PIPE
		local proc, errmsg, errno = subprocess.popen(args)
		if proc then
			if input then
				proc.stdin:write(input)
				proc.stdin:close()
			end
			local out = {}
			local err = {}
			function readpipes()
				local o = proc.stdout:read("*a")
				if o ~= "" then out[#out+1] = o end
				local e = proc.stderr:read("*a")
				if e ~= "" then err[#err+1] = e end
			end
			while nil == proc:poll() do
				readpipes()
				posix.sleep(0)
			end
			readpipes()
			proc:wait()
			proc.stdout:close()
			proc.stderr:close()
			output = table.concat(out, "") or ""
			if proc.exitcode == 0 and include_err and #err > 0 then
				output = table.concat(err, "")..output
			elseif proc.exitcode ~= 0 then
				errtxt = table.concat(err, "") or "Unknown error"
			end
		else
			errtxt = errmsg or "Unknown failure"
		end
	end)
	if not res or err then
		errtxt = err or "Unknown failure"
	end
	return output, errtxt
end

return mymodule
