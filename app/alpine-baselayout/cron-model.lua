local mymodule = {}

posix = require("posix")
modelfunctions = require("modelfunctions")
format = require("acf.format")
fs = require("acf.fs")
validator = require("acf.validator")

local configfile = "/etc/crontabs/root"
local processname = "crond"
local packagename = "busybox"
local baseurl = "/etc/periodic/"

local periods
-- ################################################################################
-- LOCAL FUNCTIONS

local function list_periods()
	if not periods then
		periods = {}
		local file = fs.read_file(configfile) or ""
		for dir in string.gmatch(file, baseurl.."(%S+)") do
			periods[#periods+1] = dir
		end
--[[	local reverseperiods = {}
	for i,per in ipairs(periods) do reverseperiods[per] = i end
	if fs.is_dir(baseurl) then
		for dir in posix.files(baseurl) do
			if fs.is_dir(baseurl .. dir) and (dir ~= ".") and (dir ~= "..") and not reverseperiods[dir] then
				periods[#periods+1] = dir
			end
		end
	end--]]
	end
	return periods
end

local function list_jobs()
	local jobs = {}
	local alljobs = {}
	for i,period in ipairs(list_periods()) do
		local temp = {period=period, jobs={}}
		for file in fs.find("[^.]+", baseurl..period) do
			table.insert(temp.jobs, file)
			table.insert(alljobs, file)
		end
		table.sort(temp.jobs)
		jobs[#jobs+1] = temp
	end
	table.sort(alljobs)
	return jobs, alljobs
end

local function validate_filename(name)
	local success = false
	for i,per in ipairs(list_periods()) do
		if validator.is_valid_filename(name, baseurl..per) then
			success = true
			break
		end
	end
	return success
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
	return modelfunctions.getstatus(processname, packagename, "Cron Status")
end

function mymodule.listjobs()
	return cfe({ type="structure", value=list_jobs(), label="Cron Jobs" })
end

function mymodule.read_job(self, clientdata)
	return modelfunctions.getfiledetails(clientdata.name, validate_filename)
end

function mymodule.update_job(self, filedetails)
	return modelfunctions.setfiledetails(self, filedetails, validate_filename)
end

function mymodule.get_delete_job(self, clientdata)
	local result = {}
	result.filename = cfe({ value=clientdata.name or "", label="File Name" })
	return cfe({ type="group", value=result, label="Delete Cron Job" })
end

function mymodule.delete_job(self, deleterequest)
	deleterequest.errtxt = "Invalid File"
	if validate_filename(deleterequest.value.filename.value) then
		os.remove(deleterequest.value.filename.value)
		deleterequest.errtxt = nil
	end
	return deleterequest
end

function mymodule.get_move_job()
	local move = {}
	move.name = cfe({ type="select", label="Name", option=select(2, list_jobs()) })
	move.period = cfe({ type="select", label="Period", option=list_periods() })
	move.name.value = move.name.option[1] or ""
	move.period.value = move.period.option[1] or ""
	return cfe({ type="group", value=move, label="Move Job" })
end

function mymodule.move_job(self, move)
	local success = modelfunctions.validateselect(move.value.name)
	success = modelfunctions.validateselect(move.value.period) and success

	if success then
		local newpath = baseurl .. move.value.period.value .. "/" .. posix.basename(move.value.name.value)
		fs.move_file(move.value.name.value, newpath)
		move.value.name.option = select(2, list_jobs())
		move.value.name.value = newpath
	else
		move.errtxt = "Failed to move job"
	end

	return move
end

function mymodule.create_new_job()
	local newjob = {}
	newjob.name = cfe({ label="Name" })
	newjob.period = cfe({ type="select", label="Period", option=list_periods() })
	newjob.period.value = newjob.period.option[1] or ""
	return cfe({ type="group", value=newjob, label="Create New Job" })
end

function mymodule.create_job(self, newjob)
	local success = modelfunctions.validateselect(newjob.value.period)

	if newjob.value.name.value == "" then
		newjob.value.name.errtxt = "Missing File Name"
		success = false
	elseif string.find(newjob.value.name.value, "[^%w_-]") then
		newjob.value.name.errtxt = "Invalid File Name"
		success = false
	elseif posix.stat(baseurl..newjob.value.period.value.."/"..newjob.value.name.value) then
		newjob.value.name.errtxt = "File already exists"
		success = false
	end

	if success then
		fs.create_file(baseurl..newjob.value.period.value.."/"..newjob.value.name.value)
		posix.chmod(baseurl..newjob.value.period.value.."/"..newjob.value.name.value, "rwxr-xr-x")
	else
		newjob.errtxt = "Failed to create new job"
	end

	return newjob
end

function mymodule.read_configfile()
	-- FIXME validate
 	return modelfunctions.getfiledetails(configfile)
end

function mymodule.update_configfile(self, filedetails)
	-- FIXME validate
	return modelfunctions.setfiledetails(self, filedetails, {configfile})
end

return mymodule
