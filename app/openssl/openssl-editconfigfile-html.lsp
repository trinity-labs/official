<% local form, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>

<% htmlviewfunctions.displaycommandresults({"checkenvironment"}, session, true) %>

<%
if viewlibrary and viewlibrary.dispatch_component and viewlibrary.check_permission("getcachain") and page_info.orig_action == page_info.prefix..page_info.controller.."/"..page_info.action then
	viewlibrary.dispatch_component("getcachain", {cadir=form.value.cadir.value})
end
%>

<%
local pattern = string.gsub(page_info.prefix..page_info.controller, "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
local func = haserl.loadfile(page_info.viewfile:gsub(pattern..".*$", "/") .. "filedetails-html.lsp")
func(form, viewlibrary, page_info, session)
%>

<% if viewlibrary and viewlibrary.dispatch_component and viewlibrary.check_permission("checkenvironment") then
	viewlibrary.dispatch_component("checkenvironment")
end %>
