<% local form, viewlibrary, page_info, session = ... %>

<% if viewlibrary and viewlibrary.dispatch_component then
	viewlibrary.dispatch_component("status")
end %>

<%
local pattern = string.gsub(page_info.prefix..page_info.controller, "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
local func = haserl.loadfile(page_info.viewfile:gsub(pattern..".*$", "/") .. "filedetails-html.lsp")
func(form, viewlibrary, page_info, session)
%>
