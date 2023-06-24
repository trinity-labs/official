-- the password controller
local mymodule = {}

mymodule.default_action = "edit"

mymodule.edit = function (self)
	return self.handle_form(self, self.model.read_password, self.model.update_password, self.clientdata, "Save", "Set System Password", "Password Set")
end

return mymodule
