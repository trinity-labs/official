-- the openssl certificates controller
local mymodule = {}

mymodule.default_action = "status"

local sslstatus

mymodule.mvc={}
mymodule.mvc.pre_exec = function(self)
	sslstatus = self.model.getstatus(self, self.clientdata)
	if not self.redirect or self.conf.component == true then
		return
	end
	if (sslstatus.value.version.errtxt and self.conf.action ~= "status")
		or (sslstatus.value.conffile.errtxt and self.conf.action ~= "status" and self.conf.action ~= "editconfigfile" and self.conf.action ~= "checkenvironment")
		or (sslstatus.value.environment.errtxt and self.conf.action ~= "status" and self.conf.action ~= "editconfigfile" and self.conf.action ~= "checkenvironment")
		or ((sslstatus.value.cacert.errtxt or sslstatus.value.cakey.errtxt) and self.conf.action ~= "status" and self.conf.action ~= "editconfigfile" and self.conf.action ~= "putcacert" and self.conf.action ~= "generatecacert" and self.conf.action ~= "checkenvironment" and self.conf.action ~= "editdefaults")
	then
		self.redirect(self)
	end
end

-- Show openssl status
mymodule.status = function(self)
	return sslstatus
end

-- View all pending and approved requests and revoked certificates
mymodule.readall = function(self)
	return self.model.readall(self, self.clientdata)
end

-- Return all certificates (pending, approved, and revoked) for this user
mymodule.read = function(self)
	return self.model.readuser(self, self.clientdata, self.sessiondata.userinfo.userid)
end

-- Form to request a new cert
mymodule.request = function(self)
	return self.handle_form(self, self.model.getnewrequest, function(self, value, submit) return self.model.submitrequest(self, value, submit, self.sessiondata.userinfo.userid) end, self.clientdata, "Submit", "Request Certificate", "Request Submitted")
end

-- Form to edit request defaults
mymodule.editdefaults = function(self)
	return self.handle_form(self, self.model.getreqdefaults, self.model.setreqdefaults, self.clientdata, "Save", "Edit Certificate Defaults", "Defaults Set")
end

-- View request details
mymodule.viewrequest = function(self)
	return self.model.viewrequest(self, self.clientdata)
end

-- Approve the specified request
mymodule.approve = function(self)
	return self.handle_form(self, self.model.getapproverequest, self.model.approverequest, self.clientdata, "Approve", "Approve Request")
end

-- Delete the specified request
mymodule.deleterequest = function(self)
	return self.handle_form(self, self.model.getdeleterequest, function(self, value, submit) return self.model.deleterequest(self, value, submit, nil) end, self.clientdata, "Delete", "Delete Request", "Request Deleted")
end

-- Delete the specified request
mymodule.deletemyrequest = function(self)
	return self.handle_form(self, self.model.getdeleterequest, function(self, value, submit) return self.model.deleterequest(self, value, submit, self.sessiondata.userinfo.userid) end, self.clientdata, "Delete", "Delete Request", "Request Deleted")
end

-- View certificate details
mymodule.viewcert = function(self)
	return self.model.viewcert(self, self.clientdata)
end

-- Get the specified cert
mymodule.getcert = function(self)
	return self.model.getcert(self, self.clientdata)
end

-- Revoke the specified cert
mymodule.revoke = function(self)
	return self.handle_form(self, self.model.getrevokecert, self.model.revokecert, self.clientdata, "Revoke", "Revoke Certificate", "Certificate Revoked")
end

-- Delete the specified certificate
mymodule.deletecert = function(self)
	return self.handle_form(self, self.model.getdeletecert, self.model.deletecert, self.clientdata, "Delete", "Delete Certificate", "Certificate Deleted")
end

-- Submit request to renew the specified certificate
mymodule.requestrenewcert = function(self)
	return self.handle_form(self, self.model.getrenewcert, self.model.renewcert, self.clientdata, "Renew", "Renew Certificate")
end

-- Renew the specified certificate
mymodule.renewcert = function(self)
	return self.handle_form(self, self.model.getrenewcert, function(self, value, submit) return self.model.renewcert(self, value, submit, true) end, self.clientdata, "Renew", "Renew Certificate")
end

-- Get the revoked list
mymodule.getrevoked = function(self)
	return self.model.getcrl(self, self.clientdata)
end

-- Put the CA cert
mymodule.putcacert = function(self)
	return self.handle_form(self, self.model.getnewputca, self.model.putca, self.clientdata, "Upload", "Upload CA Certificate", "Certificate Uploaded")
end

mymodule.downloadcacert = function(self)
        return self.model.getca(self, self.clientdata)
end
		
-- Generate a self-signed CA
mymodule.generatecacert = function(self)
	return self.handle_form(self, self.model.getnewcarequest, self.model.generateca, self.clientdata, "Generate", "Generate CA Certificate", "Certificate Generated")
end

mymodule.editconfigfile = function(self)
	return self.handle_form(self, self.model.getconfigfile, self.model.setconfigfile, self.clientdata, "Save", "Edit Config File", "Config File Saved")
end

mymodule.checkenvironment = function(self)
	return self.handle_form(self, self.model.getenvironment, self.model.setenvironment, self.clientdata, "Configure", "Configure Environment", "Environment Configured")
end

mymodule.getcachain = function(self)
	return self.model.get_ca_chain(self, self.clientdata)
end

mymodule.managesubca = function(self)
	return self.handle_form(self, self.model.getsubca, self.model.createsubca, self.clientdata, "Manage", "Manage Sub-CA")
end

return mymodule
