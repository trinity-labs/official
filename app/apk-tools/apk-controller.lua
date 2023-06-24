-- the apk controller
local mymodule = {}

mymodule.default_action = "loaded"

mymodule.loaded = function(self)
	return self.model.get_loaded_packages(self, self.clientdata)
end

mymodule.available = function(self)
	return self.model.get_available_packages(self, self.clientdata)
end

mymodule.toplevel = function(self)
	return self.model.get_toplevel_packages(self, self.clientdata)
end

mymodule.dependent = function(self)
	return self.model.get_dependent_packages(self, self.clientdata)
end

mymodule.details = function(self)
	return self.model.get_package_details(self.clientdata.package)
end

mymodule.delete = function(self)
	return self.handle_form(self, self.model.get_delete_package, self.model.delete_package, self.clientdata, "Delete", "Delete Package")
end

mymodule.install = function(self)
	return self.handle_form(self, self.model.get_install_package, self.model.install_package, self.clientdata, "Install", "Install Package")
end

mymodule.upgrade = function(self)
	return self.handle_form(self, self.model.get_upgrade_package, self.model.upgrade_package, self.clientdata, "Upgrade", "Upgrade Package")
end

mymodule.cache = function(self)
	return self.handle_form(self, self.model.get_cache, self.model.update_cache, self.clientdata, "Save", "Edit Cache Settings", "Settings Saved")
end

mymodule.expert = function(self)
	return self.handle_form(self, self.model.get_configfile, self.model.update_configfile, self.clientdata, "Save", "Edit Configuration", "Configuration Saved")
end

mymodule.updateall = function(self)
	return self.handle_form(self, self.model.get_update_all, self.model.update_all, self.clientdata, "Update All", "Update All Packages")
end

mymodule.upgradeall = function(self)
	return self.handle_form(self, self.model.get_upgrade_all, self.model.upgrade_all, self.clientdata, "Upgrade All", "Upgrade All Packages")
end

return mymodule
