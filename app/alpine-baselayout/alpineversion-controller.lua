-- the alpineversion controller

local mymodule = {}

mymodule.default_action = "read"

mymodule.read = function (self )
	return self.model.get()
end

return mymodule
