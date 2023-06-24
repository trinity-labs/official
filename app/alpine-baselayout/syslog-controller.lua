local mymodule = {}

mymodule.default_action = "loginfo"

function mymodule.loginfo(self)
	return self.model.getlogging()
end

function mymodule.config(self)
	return self.handle_form(self, self.model.getconfig, self.model.updateconfig, self.clientdata, "Save", "Edit config", "Configuration Set")
end

function mymodule.expert(self)
	return self.handle_form(self, self.model.get_filedetails, self.model.update_filedetails, self.clientdata, "Save", "Edit config", "Configuration Set")
end

function mymodule.startstop(self)
	return self.handle_form(self, self.model.get_startstop, self.model.startstop_service, self.clientdata)
end

function mymodule.status(self)
	return self.model.getstatus()
end

return mymodule
