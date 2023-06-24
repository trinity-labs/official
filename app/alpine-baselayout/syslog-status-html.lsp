<% local data, viewlibrary, page_info, session = ...
htmlviewfunctions = require("htmlviewfunctions")
html = require("acf.html")
%>

<% htmlviewfunctions.displaycommandresults({"install","edit"}, session) %>
<% htmlviewfunctions.displaycommandresults({"startstop"}, session) %>

<%
local header_level = htmlviewfunctions.displaysectionstart(data, page_info)
htmlviewfunctions.displayitem(data.value.status)

htmlviewfunctions.displayitem(data.value.version)
if data.value.version and data.value.version.errtxt and viewlibrary.check_permission("apk-tools/apk/install") then
	local install = cfe({ type="form", value={}, label="Install package", option="Install", action=page_info.script.."/apk-tools/apk/install" })
	install.value.package = cfe({ type="hidden", value=data.value.version.name })
	htmlviewfunctions.displayitem(install, page_info, 0)	-- header_level 0 means display inline without header
end

htmlviewfunctions.displayitem(data.value.autostart)
if not (data.value.version and data.value.version.errtxt) and data.value.autostart and data.value.autostart.errtxt and viewlibrary.check_permission("alpine-baselayout/rc/edit") then
	local autostart = cfe({ type="link", value={}, label="Enable autostart", option="Enable", action=page_info.script.."/alpine-baselayout/rc/edit" })
	autostart.value.servicename = cfe({ type="hidden", value=data.value.autostart.name })
	autostart.value.redir = cfe({ type="hidden", value=page_info.orig_action })
	htmlviewfunctions.displayitem(autostart, page_info, 0)	-- header_level 0 means display inline without header
end
htmlviewfunctions.displaysectionend(header_level)
%>

<% if viewlibrary and viewlibrary.dispatch_component and viewlibrary.check_permission("startstop") then
	viewlibrary.dispatch_component("startstop")
end %>
