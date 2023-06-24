-- the hostname controller
local mymodule = {}

mymodule.default_action = "read"

mymodule.read = function(self)
	return self.model.get(true)
end

mymodule.edit = function(self)
	return self.handle_form(self, self.model.read_name, self.model.update_name, self.clientdata, "Save", "Edit Hostname", "Hostname Set")
end

return mymodule
