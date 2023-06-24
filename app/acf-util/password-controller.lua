local mymodule = {}
roles = require("roles")

mymodule.default_action = "editme"

function mymodule.status(self)
	return self.model.get_users(self)
end

function mymodule.editme(self)
	-- just to make sure can't modify any other user from this action
	self.clientdata.userid = self.sessiondata.userinfo.userid
	return self.handle_form(self, self.model.read_user_without_roles, self.model.update_user, self.clientdata, "Save", "Edit My Settings", "Saved user")
end

function mymodule.edituser(self)
	return self.handle_form(self, self.model.read_user, self.model.update_user, self.clientdata, "Save", "Edit User Settings", "Saved user")
end

function mymodule.newuser(self)
	return self.handle_form(self, self.model.get_new_user, self.model.create_user, self.clientdata, "Create", "Create New User", "Created user")
end

function mymodule.deleteuser(self)
	return self.handle_form(self, self.model.get_delete_user, self.model.delete_user, self.clientdata, "Delete", "Delete User", "Deleted user")
end

function mymodule.listlockevents(self)
	return self.model.list_lock_events(self, self.clientdata)
end

function mymodule.unlockuser(self)
	return self.handle_form(self, self.model.get_unlock_user, self.model.unlock_user, self.clientdata, "Unlock", "Unlock User", "Unlocked user")
end

function mymodule.unlockip(self)
	return self.handle_form(self, self.model.get_unlock_ip, self.model.unlock_ip, self.clientdata, "Unlock", "Unlock IP Address", "Unlocked IP address")
end

return mymodule
