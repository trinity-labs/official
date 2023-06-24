<% local form, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>

<% htmlviewfunctions.displaycommandresults({"updateall", "upgradeall"}, session) %>

<%
local pattern = string.gsub(page_info.prefix..page_info.controller, "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
local func = haserl.loadfile(page_info.viewfile:gsub(pattern..".*$", "/") .. "filedetails-html.lsp")
func(form, viewlibrary, page_info, session)
%>

<% if viewlibrary.check_permission("updateall") or viewlibrary.check_permission("upgradeall") then %>
<% local header_level = htmlviewfunctions.displaysectionstart(cfe({label="Update / Upgrade"}), page_info) %>
<% if viewlibrary.check_permission("updateall") then %>
	<% htmlviewfunctions.displayitem(cfe({type="form", value={}, label="Update Index", option="Update", action="updateall" }), page_info, 0) %>
<% end %>
<% if viewlibrary.check_permission("upgradeall") then %>
	<% htmlviewfunctions.displayitem(cfe({type="form", value={}, label="Upgrade All", option="Upgrade", action="upgradeall" }), page_info, 0) %>
<% end %>
<% htmlviewfunctions.displaysectionend(header_level) %>
<% end %>
