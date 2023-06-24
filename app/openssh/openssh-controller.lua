local mymodule = {}

mymodule.default_action = "status"

function mymodule.status(self)
	return self.model.getstatus()
end

function mymodule.config(self)
	return self.handle_form(self, self.model.read_config, self.model.update_config, self.clientdata, "Save", "Edit Config", "Configuration Saved")
end

function mymodule.startstop(self)
	return self.handle_form(self, self.model.get_startstop, self.model.startstop_service, self.clientdata)
end

function mymodule.expert(self)
	return self.handle_form(self, self.model.getconfigfile, self.model.setconfigfile, self.clientdata, "Save", "Edit Config", "Configuration Saved")
end

function mymodule.connectedpeers(self)
	return self.model.list_conn_peers()
end

function mymodule.listusers(self)
	return self.model.list_users()
end

function mymodule.listauth(self)
	return self.model.list_auths(self.clientdata.user)
end

function mymodule.deleteauth(self)
	return self.handle_form(self, self.model.get_delete_auth, self.model.delete_auth, self.clientdata, "Delete", "Delete Authorized Key", "Key Deleted")
end

function mymodule.addauth(self)
	return self.handle_form(self, function() return self.model.get_auth(self.clientdata.user) end, self.model.create_auth, self.clientdata, "Add", "Add New Authorized Key", "Key Added")
end

function mymodule.logfile(self)
	return self.model.get_logfile(self, self.clientdata)
end

return mymodule
