<% local form, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>

<%
if viewlibrary and viewlibrary.dispatch_component and viewlibrary.check_permission("getcachain") and page_info.orig_action == page_info.prefix..page_info.controller.."/"..page_info.action then
	viewlibrary.dispatch_component("getcachain", {cadir=form.value.cadir.value})
end
%>

<%
	form.enctype = "multipart/form-data"
	form.value.ca.type="file"
	htmlviewfunctions.displayitem(form, page_info)
%>
