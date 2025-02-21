-- Logon / Logoff model functions

local mymodule = {}

session = require ("session")
html = require ("acf.html")
fs = require ("acf.fs")
roles = require ("roles")
authenticator = require ("authenticator")

-- Report the logon status
mymodule.status = function(self)
	local result = cfe({ type="group", value={}, label="Logon Status" })
	result.value.username = cfe({ label="User Name" })
	result.value.sessionid = cfe({ value=self.sessiondata.id or "", label="Session ID" })
	if self.sessiondata.userinfo then
		result.value.username.value = self.sessiondata.userinfo.username or ""
	end
	return result
end

-- Logoff the user by deleting session data
mymodule.logoff = function (self)
	-- Unlink / delete the current session
	local result = session.unlink_session(self.conf.sessiondir, self.sessiondata.id)
	local success = (result ~= nil)
	-- Clear the current session data
	for a,b in pairs(self.sessiondata) do
		self.sessiondata[a] = nil
	end

	return cfe({ type="boolean", value=success, label="Logoff Success" })
end

mymodule.get_logon = function(self, clientdata)
	local cmdresult = cfe({ type="group", value={}, label="Logon" })
	cmdresult.value.userid = cfe({ value=self.clientdata.userid or "", label="User ID", seq=1 })
	cmdresult.value.password = cfe({ type="password", label="Password", seq=2 })
	cmdresult.value.redir = cfe({ type="hidden", value=self.clientdata.redir, label="" })
	return cmdresult
end

-- Log on new user if possible and set up userinfo in session
-- if we fail, we leave the session alone (don't log off)
mymodule.logon = function (self, logon)
	logon.errtxt = "Logon Attempt Failed"
	-- Check to see if we can log on this user id / ip addr
	local countevent = session.count_events(self.conf.sessiondir, logon.value.userid.value, self.conf.clientip, self.conf.lockouttime, self.conf.lockouteventlimit)
	if countevent then
		session.record_event(self.conf.sessiondir, logon.value.userid.value, self.conf.clientip)
	end

	if false == countevent then
		if authenticator.authenticate (self, logon.value.userid.value, logon.value.password.value) then
			-- We have a successful logon, change sessiondata
			-- for some reason, can't call this function or it skips rest of logon
			-- mymodule.logoff(self.conf.sessiondir, self.sessiondata)
			---[[ so, do this instead
			session.unlink_session(self.conf.sessiondir, self.sessiondata.id)
			-- Clear the current session data
			for a,b in pairs(self.sessiondata) do
				if a ~= "id" then self.sessiondata[a] = nil end
			end
			--]]
			self.sessiondata.id = session.random_hash(512)
			local t = authenticator.get_userinfo (self, logon.value.userid.value)
			self.sessiondata.userinfo = {}
			for name,value in pairs(t) do
				self.sessiondata.userinfo[name] = value
			end
			logon.errtxt = nil
		else
			-- We have a bad logon, log the event
			session.record_event(self.conf.sessiondir, logon.value.userid.value, self.conf.clientip)
		end
	end
	return logon
end

mymodule.list_users = function(self)
	return cfe({ type="list", value=authenticator.list_users(self), label="Users" })
end

return mymodule
