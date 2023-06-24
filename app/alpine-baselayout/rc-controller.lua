-- the rc controller

local mymodule = {}

mymodule.default_action = "status"

mymodule.status = function(self)
	return self.model.status()
end

mymodule.edit = function(self)
	return self.handle_form(self, self.model.read_runlevels, self.model.update_runlevels, self.clientdata, "Save", "Edit Service Runlevels", "Runlevels Updated")
end

mymodule.startstop = function(self)
	return self.handle_form(self, self.model.get_startstop, self.model.startstop_service, self.clientdata)
end

return mymodule
