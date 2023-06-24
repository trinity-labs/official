<% local form, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>

<%
if viewlibrary and viewlibrary.dispatch_component and viewlibrary.check_permission("getcachain") and page_info.orig_action == page_info.prefix..page_info.controller.."/"..page_info.action then
	viewlibrary.dispatch_component("getcachain", {cadir=form.value.cadir.value})
end
%>

<%
local header_level = htmlviewfunctions.displaysectionstart(form, page_info)
if form.value.status.errtxt then
	htmlviewfunctions.displayformstart(form, page_info)
	for name,value in pairs(form.value) do
		if value.type == "hidden" then
			htmlviewfunctions.displayformitem(value, name)
		end
	end
end
htmlviewfunctions.displayitem(form.value.status)
if form.value.status.errtxt then
	htmlviewfunctions.displayformend(form)
end
htmlviewfunctions.displaysectionend(header_level)
%>
