-- Logon / Logoff functions

local mymodule = {}

mymodule.default_action = "status"

-- If there are no users defined, default to creating new ADMIN user
local check_users = function(self)
	-- If there are no users defined, add privileges and dispatch password/newuser
	local users = self.model:list_users()
	if #users.value == 0 then
		self.sessiondata.permissions[self.conf.prefix].password = {}
		self.sessiondata.permissions[self.conf.prefix].password.newuser = {"temp"}
		self:dispatch(self.conf.prefix, "password", "newuser")
		self.sessiondata.permissions[self.conf.prefix].password = nil
		-- suppress the view, because the dispatch above has already handled the output
		self.conf.suppress_view = true
		return true
	end

	return false
end

-- Logon a new user based upon id and password in clientdata
mymodule.logon = function(self)
	-- First, handle special case when no users are defined
	if check_users(self) then return end

	return self.handle_form(self, self.model.get_logon, function(self, cmdresult, submit)
		-- We will handle the redirect here
		-- The session will be cleared on a successful logon, so grab the logonredirect now
		local logonredirect = self.sessiondata.logonredirect
		cmdresult = self.model.logon(self, cmdresult)
		-- If successful logon, redirect to home or welcome page
		if not cmdresult.errtxt then
			local redir = self.clientdata.redir
			if not redir or redir == "" then
				if self.sessiondata.userinfo and self.sessiondata.userinfo.home and self.sessiondata.userinfo.home ~= "" then
					redir = self.sessiondata.userinfo.home
				elseif self.conf.home and self.conf.home ~= "" then
					redir = self.conf.home
				else
					redir = "/acf-util/welcome/read"
				end
			end
			-- only copy the logonredirect if redirecting to that page
			if logonredirect and redir then
				local prefix, controller, action = self.parse_redir_string(redir)
				if logonredirect.action == action and logonredirect.controller == controller and logonredirect.prefix == prefix then
					self.sessiondata.logonredirect = logonredirect
				end
			end
			-- we always want a redirect will occur, but nothing is expecting a command result
			-- so do the redirect here instead of in handle_form and don't pass any data
			self:redirect(redir)
		end
		return cmdresult
	end, self.clientdata, "Logon", "Logon", "Logon Successful")
end

-- Log off current user and go to logon screen
mymodule.logoff = function(self)
	-- This is an unusual action in that it does not require "submit" to take an action
	local logoff = self.model.logoff(self)
	-- We have to redirect so a new session / menu is created
	self:redirect("logon")
	return logoff
end

-- Report the logon status
mymodule.status = function(self)
	return self.model.status(self)
end

return mymodule
