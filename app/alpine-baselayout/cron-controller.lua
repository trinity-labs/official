-- the cron controller
local mymodule = {}

mymodule.default_action = "status"

function mymodule.status(self)
	return self.model.getstatus()
end

function mymodule.startstop(self)
	return self.handle_form(self, self.model.get_startstop, self.model.startstop_service, self.clientdata)
end

function mymodule.listjobs(self)
	return self.model.listjobs()
end

function mymodule.editjob(self)
	return self.handle_form(self, self.model.read_job, self.model.update_job, self.clientdata, "Save", "Edit Job", "Job Saved")
end

function mymodule.deletejob(self)
	return self.handle_form(self, self.model.get_delete_job, self.model.delete_job, self.clientdata, "Delete", "Delete Job", "Job Deleted")
end

function mymodule.movejob(self)
	return self.handle_form(self, self.model.get_move_job, self.model.move_job, self.clientdata, "Move", "Move Job", "Job Moved")
end

function mymodule.createjob(self)
	return self.handle_form(self, self.model.create_new_job, self.model.create_job, self.clientdata, "Create", "Create New Job", "New Job Created")
end

function mymodule.expert(self)
	return self.handle_form(self, self.model.read_configfile, self.model.update_configfile, self.clientdata, "Save", "Edit Config File", "Configuration Set")
end

return mymodule
