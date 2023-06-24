local mymodule = {}

-- Public methods
mymodule.default_action = "update"

mymodule.update = function (self )
	return self.handle_form(self, self.model.get_update, self.model.update, self.clientdata, "Update", "Update Skin", "Skin updated")
end

return mymodule
