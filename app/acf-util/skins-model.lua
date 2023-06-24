local mymodule = {}

modelfunctions = require("modelfunctions")
fs = require("acf.fs")
format = require("acf.format")
posix = require("posix")

local function set_skins(self, skin)
	local content = "\n"..(fs.read_file(self.conf.conffile) or "")
	local count
	content,count = string.gsub(content, "\n%s*skin%s*=[^\n]*", "\nskin="..skin)
	if count == 0 then
		content = "\nskin="..skin..content
	end
	fs.write_file(self.conf.conffile, string.sub(content,2))
end

local function list_skins(self)
	local skinarray = {}
	for skin in string.gmatch(self.conf.skindir, "[^,]+") do
		for i,file in ipairs(posix.dir(self.conf.wwwdir ..skin) or {}) do
			-- Ignore files that begins with a '.' and 'cgi-bin' and only list folders
			if not ((string.match(file, "^%.")) or (string.match(file, "^cgi[-]bin")) or (string.match(file, "^static")) or (posix.stat(self.conf.wwwdir .. skin .. file).type ~= "directory")) then
				table.insert(skinarray, skin..file)
			end
		end
	end
	return skinarray
end

mymodule.get_update = function (self)
	local skin = cfe({ type="select", value="", label="Skin", option=list_skins(self) })
	if self and self.conf and self.conf.skin then
		skin.value = self.conf.skin
	end
	return cfe({ type="group", value={skin=skin}, label="Update Skin" })
end

mymodule.update = function (self, newskin)
	local success = modelfunctions.validateselect(newskin.value.skin)
	if success then
		set_skins(self, newskin.value.skin.value)
		self.conf.skin = newskin.value.skin.value
	else
		newskin.errtxt = "Failed to set skin"
	end
	return newskin
end

return mymodule
