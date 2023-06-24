<% local data, viewlibrary, page_info, session = ...
%>

<% if viewlibrary and viewlibrary.dispatch_component and viewlibrary.check_permission("status") then
	viewlibrary.dispatch_component("status")
end %>

<% if viewlibrary and viewlibrary.dispatch_component and viewlibrary.check_permission("connectedpeers") then
	viewlibrary.dispatch_component("connectedpeers")
end %>
