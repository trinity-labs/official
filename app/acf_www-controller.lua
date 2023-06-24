--[[ Code for the Alpine Configuration WEB framework
      see http://wiki.alpinelinux.org
      Copyright (C) 2007  Nathan Angelacos
      Licensed under the terms of GPL2
   ]]--
-- Required global libraries

local mymodule = {}

-- This is not in the global namespace, but future
-- require statements shouldn't need to go to the disk lib
posix = require("posix")

-- We use the parent exception handler in a last-case situation
local parent_exception_handler
local parent_create_helper_library
local parent_view_resolver

local function build_menus(self)
	m=require("menubuilder")
	roll = require ("roles")

	-- Build the permissions table
	local roles = {}
	if self.sessiondata.userinfo and self.sessiondata.userinfo.roles then
		roles = self.sessiondata.userinfo.roles
	end
	local permissions = roll.get_roles_perm(self,roles)
	self.sessiondata.permissions = permissions

	--Build the menu
	local cats = m.get_menuitems(self)
	-- now, loop through menu and remove actions without permission
	-- go in reverse so we can remove entries while looping
	for x = #cats,1,-1 do
		local cat = cats[x]
		for y = #cat.groups,1,-1 do
			local group = cat.groups[y]
			for z = #group.tabs,1,-1 do
				local tab = group.tabs[z]
				if nil == permissions[tab.prefix] or nil == permissions[tab.prefix][tab.controller] or nil == permissions[tab.prefix][tab.controller][tab.action] then
					table.remove(group.tabs, z)
				end
			end
			if 0 == #group.tabs then
				table.remove(cat.groups, y)
			end
		end
		if 0 == #cat.groups then
			table.remove(cats, x)
		end
	end
	self.sessiondata.menu = {}
	self.sessiondata.menu.cats = cats

	-- Debug: Timestamp on menu creation
	self.sessiondata.menu.timestamp = {tab="Menu_created: " .. os.date(),action="Menu_created: " .. os.date(),}
end

local check_permission = function(self, prefix, controller, action)
	--self.logevent("Trying "..(prefix or "/")..(controller or "nil").."/"..(action or "nil"))
	if nil == self.sessiondata.permissions then return false end
	if prefix and controller then
		if nil == self.sessiondata.permissions[prefix] or nil == self.sessiondata.permissions[prefix][controller] then return false end
		if action and nil == self.sessiondata.permissions[prefix][controller][action] then return false end
	end
	return true
end

local check_permission_string = function (self, str)
	local prefix, controller, action = self.parse_redir_string(str)
	if prefix == "/" then prefix = self.conf.prefix end
	if controller == "" then controller = self.conf.controller end

	if "" == action then
		action = rawget(self.worker, "default_action") or ""
	end
	return check_permission(self, prefix, controller, action)
end

-- look for a template
-- ctlr-action-view, then  ctlr-view, then action-view, then view
local find_template
find_template = function ( appdir, prefix, controller, action, viewtype )
	if string.find(appdir, ",") then
		local template
		for p in string.gmatch(appdir, "[^,]+") do
			template = find_template(p, prefix, controller, action, viewtype)
			if template then break end
		end
		return template
	end

	local targets = {
			appdir .. prefix .. "template-" .. controller .. "-" ..
				action .. "-" .. viewtype .. ".lsp",
			appdir .. prefix .. "template-" .. controller .. "-" ..
				viewtype .. ".lsp",
			appdir .. prefix .. "template-" .. action .. "-" ..
				viewtype .. ".lsp",
			appdir .. prefix .. "template-" .. viewtype .. ".lsp"
			}
	local file
	for k,v in pairs(targets) do
		file = io.open (v)
		if file then
			io.close (file)
			return v
		end
	end
	-- not found, so try one level higher
	if prefix == "/" then -- already at the top level - fail
		return nil
	end
	prefix = posix.dirname (prefix)
	return find_template ( appdir, prefix, controller, action, viewtype )
end

-- This function is made available within the view to allow loading of components
local dispatch_component = function(self, str, clientdata, suppress_view)
	-- Before we call dispatch, we have to set up conf and clientdata like it was really called for this component
	local tempconf = self.conf
	self.conf = {}
	for x,y in pairs(tempconf) do
		self.conf[x] = y
	end
	self.conf.component = true
	self.conf.suppress_view = suppress_view
	self.conf.orig_action = self.conf.orig_action or self.conf.prefix .. self.conf.controller .. "/" .. self.conf.action
	local tempclientdata = self.clientdata
	self.clientdata = clientdata or {}
	self.clientdata.sessionid = tempclientdata.sessionid

	local prefix, controller, action = self.parse_redir_string(str)
	if prefix == "/" then prefix = self.conf.prefix end
	if controller == "" then controller = self.conf.controller end
	local viewtable = self.dispatch(self, prefix, controller, action)

	-- Revert to the old conf and clientdata
	self.conf = nil
	if not (self.conf) then self.conf = tempconf end
	self.clientdata = nil
	if not (self.clientdata) then self.clientdata = tempclientdata end

	return viewtable
end

local has_view = function(self)
	for p in string.gmatch(self.conf.appdir, "[^,]+") do
		local file = posix.stat(p .. self.conf.prefix .. self.conf.controller .. "-" .. self.conf.action .. "-" .. self.conf.viewtype .. ".lsp", "type")
		if file == "regular" or file == "link" then return true end
	end
	return false
end

-- If we've done something, cause a redirect to the referring page (assuming it's different)
-- Also handles retrieving the result of a previously redirected action
local redirect_to_referrer = function(self, result)
	if self.conf.viewtype ~= "html" then
		return result
	end
	if result and not self.conf.component then
		-- If we have a result, then we did something, so we might have to redirect
		if not ENV.HTTP_REFERER then
			-- If no referrer, we have a potential problem.
			if not self.find_view(self.conf.appdir, self.conf.prefix, self.conf.controller, self.conf.action, self.conf.viewtype or "html") then
				-- Action does not have view, so redirect to default action for this controller.
				self:redirect()
			end
		else
			local p = ENV.HTTP_REFERER:gsub("%?.*", ""):gsub("%%(%x%x)",
				function(h) return string.char(tonumber(h, 16)) end )
			local prefix, controller, action = self.parse_path_info(p)
			if prefix ~= self.conf.prefix or controller ~= self.conf.controller or action ~= self.conf.action then
				self.sessiondata[self.conf.action.."result"] = result
				error({type="redir_to_referrer"})
			end
		end
	elseif self.sessiondata[self.conf.action.."result"] then
		-- If we don't have a result, but there's a result in the session data,
		-- then we're a component redirected as above.  Return the last result.
		result = cfe(self.sessiondata[self.conf.action.."result"])
		self.sessiondata[self.conf.action.."result"] = nil
	end
	return result
end

-- Override the mvc create_helper_library function to add our functions
mymodule.create_helper_library = function ( self )
	-- Call the mvc version
	local library = parent_create_helper_library(self)
--[[	-- If we have a separate library, here's how we could do it
	local library = require("library_name")
	for name,func in pairs(library) do
		if type(func) == "function" then
			library.name = function(...) return func(self, ...) end
		end
	end
--]]
	library.dispatch_component = function(...) return dispatch_component(self, ...) end
	library.check_permission = function(...) return check_permission_string(self, ...) end
	return library
end

-- Our local view resolver called by our dispatch - add the template and skin
mymodule.view_resolver = function(self)
	self.conf.viewtype = self.conf.viewtype or "html"
	local viewfunc, viewlibrary, pageinfo = parent_view_resolver(self)
	pageinfo.viewfunc = viewfunc
	pageinfo.skinned = self.clientdata.skinned or "true"

	if self.sessiondata.userinfo and self.sessiondata.userinfo.skin and self.sessiondata.userinfo.skin ~= "" then
		pageinfo.skin = self.sessiondata.userinfo.skin
	else
		pageinfo.skin = self.conf.skin or ""
	end

	-- search for template
	local template
	if self.conf.component ~= true then
		-- First, check for skin-specific template
		if pageinfo.skin ~= "" then
			template = find_template ( self.conf.wwwdir..pageinfo.skin, "/",
				self.conf.controller, self.conf.action, self.conf.viewtype )
		end
		if not template then
			template = find_template ( self.conf.appdir, self.conf.prefix,
				self.conf.controller, self.conf.action, self.conf.viewtype )
		end
	end

	local func = viewfunc
	if template then
		-- We have a template, use it as the function
		func = haserl.loadfile (template)
	end

	return func, viewlibrary, pageinfo, self.sessiondata
end

mymodule.mvc = {}
mymodule.mvc.on_load = function (self, parent)
	-- open the log file
	if self.conf.logfile then
		self.conf.loghandle = io.open (self.conf.logfile, "a+")
	end

	--self.logevent("acf_www-controller mvc.on_load")

	-- Make sure we have some kind of sane defaults for libdir, wwwdir, and sessiondir
	self.conf.libdir = self.conf.libdir or ( string.match(self.conf.appdir, "[^,]+/") .. "/lib/" )
	self.conf.wwwdir = self.conf.wwwdir or ( string.match(self.conf.appdir, "[^,]+/") .. "/www/" )
	self.conf.sessiondir = self.conf.sessiondir or "/tmp/"
	self.conf.script = ENV.SCRIPT_NAME
	self.clientdata = FORM
	self.conf.clientip = ENV.REMOTE_ADDR

	parent_exception_handler = parent.exception_handler
	parent_create_helper_library = parent.create_helper_library
	parent_view_resolver = parent.view_resolver

	sessionlib=require ("session")

	-- before we look at sessions, remove old sessions and events
	-- this prevents us from giving a "session timeout" message, but I'm ok with that
	sessionlib.expired_events(self.conf.sessiondir, self.conf.sessiontimeout)

	-- Load the session data
	self.sessiondata = nil
	self.sessiondata = {}
	if nil ~= self.clientdata.sessionid then
		--self.logevent("Found session id = " .. self.clientdata.sessionid)
		-- Load existing session data
		local timestamp
		timestamp, self.sessiondata =
			sessionlib.load_session(self.conf.sessiondir,
				self.clientdata.sessionid)
		if timestamp == nil then
			-- invalid session id, report event and create new one
			sessionlib.record_event(self.conf.sessiondir, nil, self.conf.clientip)
			--self.logevent("Didn't find session")
		else
			--self.logevent("Found session")
			-- We read in a valid session, check if it's ok
			if self.sessiondata.userinfo and self.sessiondata.userinfo.userid and sessionlib.count_events(self.conf.sessiondir, self.sessiondata.userinfo.userid, self.conf.clientip, self.conf.lockouttime, self.conf.lockouteventlimit) then
				--self.logevent("Bad session, erasing")
				-- Too many events on this id / ip, kill the session
				sessionlib.unlink_session(self.conf.sessiondir, self.clientdata.sessionid)
				self.sessiondata.id = nil
			end
		end
	end

	if not (self.sessiondata.userinfo and self.sessiondata.userinfo.userid) and ENV.REMOTE_USER then
		-- We do not have a valid user in session data, but we have successful HTTP auth
		-- Kill the existing session
		if (self.sessiondata.id and self.clientdata.sessionid) then
			sessionlib.unlink_session(self.conf.sessiondir, self.clientdata.sessionid)
		end
		self.sessiondata = {}
		self.sessiondata.id = sessionlib.random_hash(512)
		authenticator = require("authenticator")
		self.sessiondata.userinfo = authenticator.get_userinfo(self, ENV.REMOTE_USER)
		if not self.sessiondata.userinfo then
			self.sessiondata.userinfo = {userid=ENV.REMOTE_USER, roles={"DEFAULT"}}
		end
		self.logevent("Automatic logon as ENV.REMOTE_USER: "..tostring(ENV.REMOTE_USER))
	end

	if nil == self.sessiondata.id then
		self.sessiondata = {}
		self.sessiondata.id = sessionlib.random_hash(512)
		--self.logevent("New session = " .. self.sessiondata.id)
	end
	if nil == self.sessiondata.permissions or nil == self.sessiondata.menu then
		--self.logevent("Build menus")
		build_menus(self)
	end
end

mymodule.mvc.on_unload = function (self)
	sessionlib=require ("session")
	if self.sessiondata.id then
		sessionlib.save_session(self.conf.sessiondir, self.sessiondata)
        end
	-- Close the logfile
	--self.logevent("acf_www-controller mvc.on_unload")
	if self.conf.loghandle then
		self.conf.loghandle:close()
	end
end

-- Overload the MVC's exception handler with our own to handle redirection
mymodule.exception_handler = function (self, message )
	local html = require ("acf.html")
	local viewtable
	if type(message) == "table" then
		if self.conf.component == true then
			io.write ("Component cannot be found")
		elseif message.type == "dispatch" and self.sessiondata.userinfo and self.sessiondata.userinfo.userid then
			viewtable = message
			self.conf.prefix = "/"
			self.conf.controller = "dispatcherror"
			self.conf.action = ""
		elseif message.type == "redir" or message.type == "redir_to_referrer" or message.type == "dispatch" then
			--if self.sessiondata.id then self.logevent("Redirecting " .. self.sessiondata.id) end
			io.write ("Status: 302 Moved\n")
			if message.type == "redir" then
				io.write ("Location: " .. ENV["SCRIPT_NAME"] ..
				  	message.prefix .. message.controller ..
					"/" .. message.action ..
					(message.extra or "" ) .. "\n")
			elseif message.type == "dispatch" then
				-- We got a dispatch error because the user session timed out
				-- We want to save the URL and any get / post data to resubmit after logon
				self.sessiondata.logonredirect = message
				self.sessiondata.logonredirect.clientdata = self.clientdata
				self.sessiondata.logonredirect.clientdata.sessionid = nil
				self.sessiondata.logonredirect.referrer = ENV.HTTP_REFERER
				if message.controller ~= "" then
					io.write ("Location: " .. ENV["SCRIPT_NAME"] .. "/acf-util/logon/logon?redir="..message.prefix..message.controller.."/"..message.action.."\n")
				else
					io.write ("Location: " .. ENV["SCRIPT_NAME"] .. "/acf-util/logon/logon\n")
				end
			else
				io.write ("Location: " .. ENV.HTTP_REFERER .. "\n")
			end
			if self.sessiondata.id then
				io.write (html.cookie.set("sessionid", self.sessiondata.id))
			else
				io.write (html.cookie.unset("sessionid"))
			end
			io.write ( "Content-Type: text/html\n\n" )
		else
			parent_exception_handler(self, message)
		end
	else
		self.logevent("Exception: "..message)
		viewtable = {message = message}
		self.conf.prefix = "/"
		self.conf.controller = "exception"
		self.conf.action = ""
	end

	if viewtable then
		if not self.conf.suppress_view then
			local success, err = xpcall ( function ()
				local viewfunc, p1, p2, p3 = self.view_resolver(self)
				viewfunc (viewtable, p1, p2, p3)
			end,
			self:soft_traceback()
			)

			if not success then
				parent_exception_handler(self, err)
			end
		end
	end
end

-- Overload the MVC's dispatch function with our own
-- check permissions and redirect if not allowed to see
-- pass more parameters to the view
-- allow display of views without actions
mymodule.dispatch = function (self, userprefix, userctlr, useraction)
	local controller = nil
	local viewtable
	local starttime = os.time()
	local success, err = xpcall ( function ()

	if userprefix == nil then
		self.conf.prefix, self.conf.controller, self.conf.action =
			self.parse_path_info(ENV["PATH_INFO"])
		self.conf.wwwprefix = string.gsub(ENV["SCRIPT_NAME"] or "", "/?cgi%-bin/acf.*", "")
	else
		self.conf.prefix = userprefix or "/"
		self.conf.controller = userctlr or ""
		self.conf.action = useraction or ""
	end
	--self.logevent("WWW.dispatch "..self.conf.prefix..self.conf.controller.."/"..self.conf.action)

	-- This is for get / post data saved for after logon
	if self.sessiondata.logonredirect and self.conf.prefix == self.sessiondata.logonredirect.prefix
	and self.conf.controller == self.sessiondata.logonredirect.controller
	and self.conf.action == self.sessiondata.logonredirect.action then
		ENV.HTTP_REFERER = self.sessiondata.logonredirect.referrer or ENV.HTTP_REFERER
		self.clientdata = self.sessiondata.logonredirect.clientdata
		self.sessiondata.logonredirect = nil
	end

	-- Before we start checking for views, set the viewtype (also before any redirect or dispatch error)
	if self.clientdata.viewtype then
		self.conf.viewtype = self.clientdata.viewtype
	else
		self.conf.viewtype = "html"
	end

	-- Find the proper prefix/controller/action combo
	local origconf = {}
	for name,value in pairs(self.conf) do origconf[name]=value end
	if "" == self.conf.controller and self.sessiondata.userinfo and self.sessiondata.userinfo.home and self.sessiondata.userinfo.home ~= "" then
		self.conf.prefix, self.conf.controller, self.conf.action =
			self.parse_path_info(self.sessiondata.userinfo.home)
	end
	if "" == self.conf.controller and self.conf.home and self.conf.home ~= "" then
		self.conf.prefix, self.conf.controller, self.conf.action =
			self.parse_path_info(self.conf.home)
	end
	if "" == self.conf.controller then
		self.conf.prefix = "/acf-util/"
		self.conf.controller = "welcome"
		self.conf.action = "read"
	end

	-- If we have different prefix / controller / action, redirect
	if self.conf.prefix ~= origconf.prefix or self.conf.controller ~= origconf.controller or self.conf.action ~= origconf.action then
		self:redirect(self.conf.action) -- controller and prefix already in self.conf
	end

	if "" ~= self.conf.controller then
		-- We now know the prefix / controller / action combo, check if we're allowed to do it
		local perm = check_permission(self, self.conf.prefix, self.conf.controller)
		local worker_loaded = false

		if perm then
			controller, worker_loaded = self:new(self.conf.prefix .. self.conf.controller)
		end
		if worker_loaded then
			local default_action = rawget(controller.worker, "default_action") or ""
			if self.conf.action == "" then self.conf.action = default_action end
			if "" ~= self.conf.action then
				local perm = check_permission(controller, self.conf.prefix, self.conf.controller, self.conf.action)
				-- Because of the inheritance, normally the
				-- controller.worker.action will flow up, so that all children have
				-- actions of all parents.  We use rawget to make sure that only
				-- controller defined actions are used on dispatch
				if (not perm) or (type(rawget(controller.worker, self.conf.action)) ~= "function") then
					controller:destroy()
					controller = nil
				end
			end
		elseif controller then
			controller:destroy()
			controller = nil
		end
	end

	-- If the controller or action are missing, display an error view
	if nil == controller then
		-- If we have a view w/o an action, just display the view (passing in the clientdata)
		if (not self.conf.suppress_view) and has_view(self) and check_permission(self, self.conf.prefix, self.conf.controller, self.conf.action) then
			viewtable = self.clientdata
		else
			origconf.type = "dispatch"
			error (origconf)
		end
	end

	if controller then
		-- run the (first found) pre_exec code, starting at the controller
		-- and moving up the parents
		if  type(controller.worker.mvc.pre_exec) == "function" then
			controller.worker.mvc.pre_exec ( controller )
		end

		-- run the action
		viewtable = controller.worker[self.conf.action](controller)

		-- run the post_exec code
		if  type(controller.worker.mvc.post_exec) == "function" then
			controller.worker.mvc.post_exec ( controller )
		end

		-- we're done with the controller, destroy it
		controller:destroy()
		controller = nil
	end

	if not self.conf.suppress_view then
		local viewfunc, p1, p2, p3 = self.view_resolver(self)
		viewfunc (viewtable, p1, p2, p3)
	end

	end,
	self:soft_traceback(message)
	)

	if not success then
		if controller then
			controller:exception_handler(err)
			controller:destroy()
			controller = nil
		else
			self:exception_handler(err)
		end
	end

	--self.logevent(self.conf.prefix..self.conf.controller.."/"..self.conf.action.." took"..os.difftime(os.time(), starttime))

	return viewtable
end

-- Cause a redirect to specified (or default) action
-- We use the self.conf table because it already has prefix,controller,etc
-- The actual redirection is defined in exception_handler above
mymodule.redirect = function (self, str, result)
	if self.conf.viewtype ~= "html" then
		return
	end
	if result then
		self.sessiondata[self.conf.action.."result"] = result
	end
	local prefix, controller, action = self.parse_redir_string(str)
	if prefix ~= "/" then self.conf.prefix = prefix end
	if controller ~= "" then self.conf.controller = controller end

	if "" == action then
		action = rawget(self.worker, "default_action") or ""
	end
	self.conf.action = action
	self.conf.type = "redir"
	error(self.conf)
end

-- parse a "URI" like string into a prefix, controller and action
-- this is the same as URI string, but opposite preference
-- if only one is defined, it's assumed to be the action
mymodule.parse_redir_string = function( str )
	str = str or ""
	str = string.gsub(str, "/+$", "")
	local action = string.match(str, "[^/]+$") or ""
	str = string.gsub(str, "/*[^/]*$", "")
	local controller = string.match(str, "[^/]+$") or ""
	str = string.gsub(str, "/*[^/]*$", "")
	local prefix = string.match(str, "[^/]+$") or ""
	if prefix == "" then
		prefix = "/"
	else
		prefix = "/"..prefix.."/"
	end
	return prefix, controller, action
end

mymodule.logevent = function ( message )
	if mymodule.conf.loghandle then
		mymodule.conf.loghandle:write (string.format("%s: %s\n", os.date(), message or ""))
	else
		-- call to parent's handler
		mymodule.__index.logevent(message)
	end
end

mymodule.handle_clientdata = function(form, clientdata)
	clientdata = clientdata or {}
	form.errtxt = nil
	for name,value in pairs(form.value) do
		value.errtxt = nil
		if name:find("%.") and not clientdata[name] then
			-- If the name has a '.' in it, haserl will interpret it as a table
			local actualval = clientdata
			for entry in name:gmatch("[^%.]+") do
				if tonumber(entry) then
					actualval = actualval[tonumber(entry)]
				else
					actualval = actualval[entry]
				end
				if not actualval then break end
			end
			clientdata[name] = actualval
		end
		if tonumber(name) and not clientdata[name] then
			-- If the name is a number, haserl will convert the string to a number index
			clientdata[name] = clientdata[tonumber(name)]
		end
		if value.type == "group" then
			mymodule.handle_clientdata(value, clientdata[name])
		elseif value.readonly then
			-- Don't update readonly values
		elseif value.type == "boolean" then
			--- HTML forms simply don't include checkboxes unless they're checked
			value.value = (clientdata[name] ~= nil) and (clientdata[name] ~= "false")
		elseif value.type == "multi" then
			-- Multi-selects return \r separated lists or nothing at all if none selected
			value.value = {}
			if clientdata[name] and clientdata[name] ~= "" then
				-- for www we use \r separated list
				if type(clientdata[name]) == "string" then
					for l in string.gmatch(clientdata[name].."\n", "%s*([^\n]*%S)%s*\n") do
						table.insert(value.value, l)
					end
				else
					value.value = clientdata[name]
				end
			end
--[[
			-- FIXME this is because multi selects don't work in haserl
			-- Multi-selects are implemented as checkboxes, so if none exists, it means nothing is selected
			local oldtable = clientdata[name] or {}
			-- Assume it's a sparse array, and remove blanks
			local newtable={}
			for x=1,table.maxn(oldtable) do
				if oldtable[x] then
					newtable[#newtable + 1] = oldtable[x]
				end
			end
			value.value = newtable
--]]
		elseif clientdata[name] then
			-- The other types will be returned in clientdata even if set to blank, so if no result, leave the default
			if value.type == "list" then
				value.value = {}
				if clientdata[name] ~= "" then
					-- for www we use \r separated list
					for l in string.gmatch(clientdata[name].."\n", "%s*([^\n]*%S)%s*\n") do
						table.insert(value.value, l)
					end
				end
			else
				value.value = clientdata[name]
			end
		end
	end
end

mymodule.handle_form = function(self, getFunction, setFunction, clientdata, option, label, descr)
	local form = getFunction(self, clientdata)

	if clientdata.submit then
		self.handle_clientdata(form, clientdata)

		form = setFunction(self, form, clientdata.submit)
		if not form.errtxt and descr then
			form.descr = descr
		end

		if clientdata.redir then
			form.value.redir = cfe({ type="hidden", value=clientdata.redir, label="" })
		end
		if clientdata.redir and not form.errtxt then
			-- If redirecting to a different action, change the value to a command result
			local prefix, controller, action = self.parse_redir_string(clientdata.redir)
			if prefix == "/" then prefix = self.conf.prefix end
			if controller == "" then controller = self.conf.controller end
			if self.conf.prefix ~= prefix or self.conf.controller ~= controller or self.conf.action ~= action then
				form.value = form.descr -- make it a command result
				form.descr = nil
				self:redirect(clientdata.redir, form)
			end
			-- Otherwise, continue and ignore the referrer
		else
			form = redirect_to_referrer(self, form)
		end
	else
		if clientdata.redir then
			form.value.redir = cfe({ type="hidden", value=clientdata.redir, label="" })
		end
		form = redirect_to_referrer(self) or form
	end

	form.type = "form"
	form.option = option or form.option
	form.label = label or form.label

	return form
end

return mymodule
