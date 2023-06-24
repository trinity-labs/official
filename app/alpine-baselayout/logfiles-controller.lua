local mymodule = {}
posix = require("posix")

mymodule.default_action = "status"

-- Public methods

mymodule.status = function (self )
	return self.model.get()
end

mymodule.delete = function (self)
	return self.handle_form(self, self.model.get_delete, self.model.delete, self.clientdata, "Delete", "Delete File", "File Deleted")
end

mymodule.view = function (self)
	return self.model.get_filedetails(self, self.clientdata)
end

mymodule.download = function (self)
	local filedetails = mymodule.view(self)
	local filecontent = filedetails.value.filecontent
	if filecontent then
		filecontent.type = "raw"
		filecontent.label = posix.basename(filedetails.value.filename.value)
	end
	return filedetails
end

mymodule.tail = function (self)
	return self.model.tail(self, self.clientdata)
end

return mymodule
