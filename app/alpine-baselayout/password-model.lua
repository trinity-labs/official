-- password model methods
local mymodule = {}

fs = require("acf.fs")
format = require("acf.format")
posix = require("posix")

mymodule.read_password = function()
	pw = {}
	pw.user = cfe({ label="User Name", seq=1 })
	pw.password = cfe({ type="password", label="Password", seq=2 })
	pw.password_confirm = cfe({ type="password", label="Password (confirm)", seq=3 })
	return cfe({ type="group", value=pw, label="System Password" })
end

--setup so that it will compare password input
mymodule.update_password = function (self, pw)
	local success = true
	if pw.value.password.value == "" or pw.value.password.value ~= pw.value.password_confirm.value then
		pw.value.password.errtxt = "Invalid or non matching password"
		success = false
	end
	local filecontent = "\n"..(fs.read_file("/etc/shadow") or "")
	if pw.value.user.value == "" or not string.find(filecontent, "\n"..pw.value.user.value..":") then
		pw.value.user.errtxt = "Unknown user"
		success = false
	end

	if success then
		math.randomseed(os.time())
		local randomchar = function()
			local char = math.random(64)+string.byte('.')
			if char > string.byte('9') then char = char + 7 end
			if char > string.byte('Z') then char = char + 6 end
			return string.char(char)
		end
		local seed = randomchar() .. randomchar()
		newpass = posix.crypt(pw.value.password.value, seed)
		local new = string.gsub(filecontent, "(\n"..pw.value.user.value..":)[^:]*", "%1"..newpass)
		fs.write_file("/etc/shadow", string.sub(new, 2))
	else
		pw.errtxt = "Failed to set password"
	end

	return pw
end

return mymodule
