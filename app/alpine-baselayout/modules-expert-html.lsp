<% local form, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>

<% htmlviewfunctions.displaycommandresults({"reload"}, session) %>

<% if viewlibrary and viewlibrary.dispatch_component then
	viewlibrary.dispatch_component("edit")
end %>

<% if viewlibrary and viewlibrary.dispatch_component then
	viewlibrary.dispatch_component("reload")
end %>
