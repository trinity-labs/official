local mymodule = {}

mymodule.default_action = "system"

-- Public methods

mymodule.system = function (self)
	return self.model:get_system()
end

mymodule.storage = function (self)
	return self.model:get_storage()
end

mymodule.network = function (self)
	return self.model:get_network()
end

mymodule.proc = function (self)
	return self.model:get_proc()
end

mymodule.api = function (self)
	return self.model:get_api()
end

mymodule.networkstats = function(self)
	local retval = self.model.get_networkstats()
	if self.conf.viewtype == "html" then
		local intf = self:new("alpine-baselayout/interfaces")
		local interfaces = intf.model.get_addresses()
		intf:destroy()
		for i,intf in ipairs(interfaces.value) do
			if retval.value[intf.interface] then
				retval.value[intf.interface].ipaddr = intf.ipaddr
			end
		end
	end
	return retval
end

return mymodule
