-- the modules  controller
local mymodule = {}

mymodule.default_action = "status"

mymodule.status = function(self)
	return self.model.read_modules()
end

mymodule.edit = function(self)
	return self.handle_form(self, self.model.read_file, self.model.write_file, self.clientdata, "Save", "Edit Modules file", "File saved")
end

mymodule.reload = function(self)
	return self.handle_form(self, self.model.get_reloadmodules, self.model.reloadmodules, self.clientdata, "Reload", "Reload Modules")
end

return mymodule
