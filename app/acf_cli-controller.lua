local mymodule = {}

posix = require("posix")
session = require("session")

local parent_exception_handler

mymodule.mvc = {}
mymodule.mvc.on_load = function (self, parent)
	-- Make sure we have some kind of sane defaults for libdir
	self.conf.libdir = self.conf.libdir or ( string.match(self.conf.appdir, "[^,]+/") .. "/lib/" )
	self.conf.script = ""
	self.conf.viewtype = "serialized"

	parent_exception_handler = parent.exception_handler

	-- this sets the package path for us and our children
	for p in string.gmatch(self.conf.libdir, "[^,]+") do
		package.path=  p .. "?.lua;" .. package.path
	end

	self.session = {}
end

mymodule.exception_handler = function (self, message )
	print(session.serialize("exception", message))
	parent_exception_handler(self, message)
end

mymodule.handle_clientdata = function(form, clientdata, group)
	clientdata = clientdata or {}
	form.errtxt = nil
	for n,value in pairs(form.value) do
		value.errtxt = nil
		local name = n
		if group then name = group.."."..name end
		if value.type == "group" then
			mymodule.handle_clientdata(value, clientdata, name)
		elseif value.readonly then
			-- Don't update readonly values
		-- Don't update from the default unless a value exists
		elseif value.type == "boolean" and clientdata[name] then
			value.value = (clientdata[name] == "true")
		elseif value.type == "multi" or value.type == "list" then
			-- for cli we use name[num] as the name
			local temp = {}
			for n,val in pairs(clientdata) do
				if string.find(n, "^"..name.."%[%d+%]$") then
					temp[tonumber(string.match(n, "%[(%d+)%]$"))] = val
				end
			end
			-- Use clientdata[name] to specify empty list
			if #temp > 0 or clientdata[name] then
				value.value = temp
			end
		else
			value.value = clientdata[name] or value.value
		end
	end
end

return mymodule
