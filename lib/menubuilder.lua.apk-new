--[[ parse through the *.menu tables and return a "menu" table
     Written for Alpine Configuration Framework (ACF) -- see www.alpinelinux.org
     Copyright (C) 2007  Nathan Angelacos
     Licensed under the terms of GPL2
  ]]--
local mymodule = {}

posix = require("posix")
format = require("acf.format")
fs = require("acf.fs")

-- returns a table of the "*.menu" tables
-- startdir should be the app dir.
local get_candidates = function (startdir)
	return fs.find_files_as_array(".*%.menu", startdir, true)
end

-- Split string into priority and name, convert '_' to space
local parse_menu_entry = function (entry)
	local name, priority
	if (string.match(entry, "^%d")) then
		priority, name = string.match(entry, "(%d+)(.*)")
	else
		name = entry
	end
	name = string.gsub(name, "_", " ")
	return name, priority
end

-- Parse menu file entry, returning cat, group, tab, action and priorities
local parse_menu_line = function (line)
	local result = nil
	--skip comments and blank lines
	if nil == (string.match(line, "^#") or string.match(line,"^$")) then
		local item = {}
		for i in string.gmatch(line, "%S+") do
			item[#item + 1] = i
		end
		if #item >= 1 then
			result = {}
			result.cat, result.cat_prio = parse_menu_entry(item[1])
			if (item[2]) then result.group, result.group_prio = parse_menu_entry(item[2]) end
			if (item[3]) then result.tab, result.tab_prio = parse_menu_entry(item[3]) end
			if (item[4]) then result.action = parse_menu_entry(item[4]) end
		end
	end
	return result
end

-- Function to sort by priority, missing priority moves to the end, same priority maintains initial order
local sort_by_prio = function(tab)
	local reversetab = {}
	for i,t in ipairs(tab) do
		reversetab[t.name] = i
	end
	prio_compare = function(x,y)
		if x.priority == y.priority then
			return reversetab[x.name] < reversetab[y.name]
		end
		if nil == x.priority then return false end
		if nil == y.priority then return true end
		return tonumber(x.priority) < tonumber(y.priority)
	end
	table.sort(tab, prio_compare)
end

-- returns a table of all the menu items found, sorted by priority
mymodule.get_menuitems = function (self)
	local cats = {}
	local reversecats = {}
	local foundcontrollers = {}
	for p in string.gmatch(self.conf.appdir, "[^,]+") do
		p = (string.gsub(p, "/$", ""))	--remove trailing /
		for k,filename in pairs(get_candidates(p)) do
			local controller = string.gsub(posix.basename(filename), ".menu$", "")
			local prefix = (string.gsub(posix.dirname(filename), p, "")).."/"
			if not foundcontrollers[prefix.."/"..controller] then
				foundcontrollers[prefix.."/"..controller] = true

				-- open the menu file, and parse the contents
				local handle = io.open(filename)
				for x in handle:lines() do
					local result = parse_menu_line(x)
					if result then
						for i = 1,1 do	-- loop so break works
							-- Add the category
							if nil == reversecats[result.cat] then
								table.insert ( cats,
									{ name=result.cat,
									groups = {},
									reversegroups = {} } )
								reversecats[result.cat] = #cats
							end
							local cat = cats[reversecats[result.cat]]
							cat.priority = cat.priority or result.cat_prio
							-- Add the group
							if nil == result.group then break end
							if nil == cat.groups[cat.reversegroups[result.group]] then
								table.insert ( cat.groups,
									{ name = result.group,
									controllers = {},
									reversetabs = {},
									tabs = {} } )
								cat.reversegroups[result.group] = #cat.groups
							end
							cat.groups[cat.reversegroups[result.group]].controllers[prefix..controller] = true
							local group = cat.groups[cat.reversegroups[result.group]]
							group.priority = group.priority or result.group_prio
							-- Add the tab
							if nil == result.tab or nil == result.action then break end
							local tab = { name = result.tab,
								controller = controller,
								prefix = prefix,
								action = result.action,
								priority = result.tab_prio}
							table.insert(group.tabs, tab)
							if group.reversetabs[tab.name] then
								-- Flag for two tabs of same name in different controllers
								for i,t in ipairs(group.reversetabs[tab.name]) do
									if group.tabs[t].controller ~= tab.controller or group.tabs[t].prefix ~= tab.prefix then
										group.flag = tab.name
										break
									end
								end
								table.insert(group.reversetabs[tab.name], #group.tabs)
							else
								group.reversetabs[tab.name] = {#group.tabs}
							end
						end
					end
				end
				handle:close()
			end
		end
	end

	-- Now that we have the entire menu, sort by priority
	-- Categories first
	sort_by_prio(cats)

	-- Then groups
	for x, cat in ipairs(cats) do
		-- Let's check for bad groups (multiple tabs with same name)
		for y,group in ipairs(cat.groups) do
			if group.flag then
				-- determine the difference between prefix/controller combos (start and stop chars)
				local start=0
				local done = false
				local first = ""
				for con in pairs(group.controllers) do
					first = con
					break
				end
				while not done and start<first:len() do
					start = start+1
					for con in pairs(group.controllers) do
						if con:sub(start,start) ~= first:sub(start,start) then
							done = true
							break
						end
					end
				end
				local stop=0
				done = false
				while not done and stop+first:len()>0 do
					stop = stop-1
					for con in pairs(group.controllers) do
						if con:sub(stop,stop) ~= first:sub(stop,stop) then
							done = true
							break
						end
					end
				end

				-- create new groups for each prefix/controller
				for con in pairs(group.controllers) do
					table.insert ( cat.groups,
						{ name = group.name..string.sub(con,start,stop),
						controllers = {},
						priority = group.priority,
						reversetabs = {},
						tabs = {} } )
					cat.groups[#cat.groups].controllers[con] = true
					cat.reversegroups[group.name..con] = #cat.groups
				end
				-- move the tabs into appropriate groups
				for z,tab in ipairs(group.tabs) do
					table.insert(cat.groups[cat.reversegroups[group.name..tab.prefix..tab.controller]].tabs, tab)
				end
				-- remove the group
				group.tabs = {}
			end
			group.reversetabs = nil -- don't need reverse table anymore
			sort_by_prio(group.tabs)
		end
		cat.reversegroups = nil	-- don't need reverse table anymore
		sort_by_prio(cat.groups)
	end

	return cats
end

return mymodule
