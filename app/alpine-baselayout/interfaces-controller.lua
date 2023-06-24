-- the interfaces  controller
local mymodule = {}

mymodule.default_action = "read"

mymodule.status = function (self)
	return self.model.get_status()
end

mymodule.read = function (self)
	return self.model.get_all_interfaces()
end

mymodule.update = function(self)
	return self.handle_form(self, self.model.get_iface_by_name, self.model.update_iface, self.clientdata, "Save", "Update Interface", "Interface updated")
end

mymodule.delete = function(self)
	return self.handle_form(self, self.model.get_delete_iface_by_name, self.model.delete_iface_by_name, self.clientdata, "Delete", "Delete Interface")
end

mymodule.ifup = function(self)
	return self.handle_form(self, self.model.get_ifup_by_name, self.model.ifup_by_name, self.clientdata, "ifup", "Interface Up")
end

mymodule.ifdown = function(self)
	return self.handle_form(self, self.model.get_ifdown_by_name, self.model.ifdown_by_name, self.clientdata, "ifdown", "Interface Down")
end

-- FIXME: 'Method' select box appeared via JS ... figure out how best to implement that when using the standard view
mymodule.create = function(self)
	return self.handle_form(self, self.model.get_iface, self.model.create_iface, self.clientdata, "Create", "Create Interface", "Interface created")
end

mymodule.editintfile = function(self)
	return self.handle_form(self, self.model.get_file, self.model.write_file, self.clientdata, "Save", "Edit Interfaces file", "File saved")
end

mymodule.restart = function(self)
	return self.handle_form(self, self.model.get_restartnetworking, self.model.restartnetworking, self.clientdata, "Restart", "Restart Networking")
end

return mymodule
