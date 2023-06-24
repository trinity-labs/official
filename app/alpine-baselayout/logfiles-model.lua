-- acf model for displaying logfiles
local mymodule = {}

posix = require("posix")
modelfunctions = require("modelfunctions")
fs = require("acf.fs")
format = require("acf.format")

-- These folders (and their subfolders) are going to be listed
local logfilepaths = {"/var/log"}

local function is_file_in_use(path)
	return (modelfunctions.run_executable({"fuser", path}) or "unknown") ~= ""
end

-- Function to recursively insert all filenames in a dir into an array
-- Links are followed and only actual files are listed
local function recursedir(path, filearray)
	filearray = filearray or {}
	local k,v
	for k,v in pairs(posix.dir(path) or {}) do
		-- Ignore files that begins with a '.'
		if not string.match(v, "^%.") then
			local file = path .. "/" .. v
			-- If subfolder exists, list files in this subfolder
			local st = posix.stat(file)
			while st and st.type == "link" do
				file = posix.readlink(file)
				st = posix.stat(file)
			end
			if st and st.type == "directory" then
				recursedir(file, filearray)
			elseif st and st.type == "regular" then
				table.insert(filearray, file)
			end
		end
	end
	return filearray
end

-- Function to list available files for view/delete
local function list_files()
	local files = {}
	-- Generate a single table with all the files
	for i,p in pairs(logfilepaths) do
		recursedir(p, files)
	end
	table.sort(files)
	return files
end

local do_grep = function(filecontent, grep)
	if grep and grep ~= "" then
		local lines = {}
		for line in string.gmatch(filecontent.value, "[^\n]*\n?") do
			if string.match(line, grep) then
				lines[#lines+1] = line
			end
		end
		filecontent.value = table.concat(lines) or ""
	end
end

mymodule.get_filedetails = function(self, clientdata)
	local retval = cfe({ type="group", value={}, label="Logfile details" })
	retval.value.filename = cfe({ label="File name", key=true })
	retval.value.grep = cfe({ label="Grep", key=true })
	self.handle_clientdata(retval, clientdata)

	local success = false
	for i,file in ipairs(list_files()) do
		if file == retval.value.filename.value then
			success = true
			break
		end
	end
	if success then
		local file = retval.value.filename.value
		local st = posix.stat(file)
		while st.type == "link" do
			file = posix.readlink(file)
			st = posix.stat(file)
		end

		local filedetails = modelfunctions.getfiledetails(file)
		for n,v in pairs(filedetails.value) do
			if n ~= "filename" then
				retval.value[n] = v
			end
		end
		if filedetails.errtxt then
			retval.errtxt = filedetails.errtxt
		else
			do_grep(retval.value.filecontent, retval.value.grep.value)
		end
	else
		retval.errtxt = "Invalid log file"
	end
	return retval
end

mymodule.tail = function(self, clientdata)
	local retval = cfe({ type="group", value={}, label="Tail Logfile" })
	retval.value.filename = cfe({ label="File name", key=true })
	retval.value.offset = cfe({ value="0", label="File offset", key=true })
	retval.value.grep = cfe({ label="Grep", key=true })
	self.handle_clientdata(retval, clientdata)

	retval.value.size = cfe({ value="0", label="File size" })
	retval.value.filecontent = cfe({ type="longtext", label="File content" })

	retval.value.filename.errtxt = "File not found"
	for i,file in ipairs(list_files()) do
		if ( file == retval.value.filename.value ) then
			retval.value.filename.errtxt = nil
			local f = io.open(retval.value.filename.value)
			if tonumber(retval.value.offset.value) then
				local offset = tonumber(retval.value.offset.value)
				if offset < 0 then
					f:seek("end", offset)
				else
					f:seek("set", offset)
				end
				retval.value.filecontent.value = f:read("*all")
				retval.value.size.value = f:seek()
			else
				retval.value.size.value = f:seek("end")
				retval.value.offset.value = retval.value.size.value
			end
			f:close()
			do_grep(retval.value.filecontent, retval.value.grep.value)
			break
		end
	end

	return retval
end

mymodule.get = function ()
	local retval = {}
	for i,file in pairs(list_files()) do
		local details = posix.stat(file)
		details.filename = file
		details.inuse = is_file_in_use(file)
		table.insert(retval, details)
	end
	table.sort(retval, function(a,b) return a.filename < b.filename end)
	return cfe({ type="structure", value=retval, label="Log Files" })
end

mymodule.get_delete = function()
	local filename = cfe({ type="select", label="File name", option=list_files() })

	return cfe({ type="group", value={filename=filename}, label="Delete logfile" })
end

-- Function to check if a file is deletable, and if it is, then delete it.
mymodule.delete = function (self, filetodelete)
	local success = modelfunctions.validateselect(filetodelete.value.filename)

	if success then
		-- Check if file is deletable (or in use)
		if is_file_in_use(filetodelete.value.filename.value) then
			success = false
			filetodelete.value.filename.errtxt = "File in use"
		else
			local file = filetodelete.value.filename.value
			local st = posix.stat(file)
			while st.type == "link" do
				file = posix.readlink(file)
				st = posix.stat(file)
			end
			local status, err = os.remove(file)
			if err then
				success = false
				filetodelete.value.filename.errtxt = err
			end
		end
	end

	if not success then
		filetodelete.errtxt = "Failed to delete file"
	end

	return filetodelete
end

return mymodule
