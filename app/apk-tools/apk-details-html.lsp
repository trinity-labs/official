<% local data, viewlibrary, page_info, session = ... 
html = require("acf.html")
htmlviewfunctions = require("htmlviewfunctions")
%>

<% htmlviewfunctions.displaycommandresults({"install", "upgrade"}, session) %>

<% local header_level = htmlviewfunctions.displaysectionstart(data, page_info) %>
<%
htmlviewfunctions.displayitem(data.value.package)
htmlviewfunctions.displayitem(data.value.installed)
htmlviewfunctions.displayitem(data.value.version)
htmlviewfunctions.displayitem(data.value.comment)
htmlviewfunctions.displayitem(data.value.webpage)
htmlviewfunctions.displayitem(data.value.size)
htmlviewfunctions.displayitem(data.value.upgrade)
%>

<% local packagecfe = cfe({ type="hidden", value=data.value.package.value }) %>
<% local redir = cfe({ type="hidden", value=page_info.orig_action.."?package="..html.url_encode(data.value.package.value) }) %>
<% if viewlibrary.check_permission("install") and data.value.installed.value == "" then %>
	<% htmlviewfunctions.displayitem(cfe({type="form", value={package=packagecfe, redir=redir}, label="Install", option="Install", action="install" }), page_info, 0) %>
<% elseif viewlibrary.check_permission("upgrade") and data.value.upgrade.value ~= "" then %>
	<% htmlviewfunctions.displayitem(cfe({type="form", value={package=packagecfe, redir=redir}, label="Upgrade", option="Upgrade", action="upgrade" }), page_info, 0) %>
<% end %>

<% htmlviewfunctions.displaysectionend(header_level) %>
