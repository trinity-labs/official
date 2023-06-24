<% local form, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>

<% htmlviewfunctions.displaycommandresults({"delete", "install", "upgrade"}, session) %>

<% if viewlibrary and viewlibrary.dispatch_component then
	if viewlibrary.check_permission("toplevel") then
		viewlibrary.dispatch_component("toplevel")
	end
	if viewlibrary.check_permission("dependent") then
		viewlibrary.dispatch_component("dependent")
	end
end %>
