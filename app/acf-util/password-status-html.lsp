<% local form, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>

<% htmlviewfunctions.displaycommandresults({"newuser", "edituser", "deleteuser", "unlockuser"}, session) %>

<%
local header_level = htmlviewfunctions.displaysectionstart(form, page_info)
local header_level2 = htmlviewfunctions.incrementheader(header_level)
local redir = cfe({ type="hidden", value=page_info.orig_action })
htmlviewfunctions.displayitem(cfe({ type="link", value={redir=redir}, label="Create New Account", option="Create", action="newuser" }), page_info, header_level2)

htmlviewfunctions.displaysectionstart(cfe({label="Existing Accounts"}), page_info, header_level2)
for i,user in ipairs(form.value) do
	local name = html.html_escape(user.value.userid.value)
	htmlviewfunctions.displayitemstart() %>
	<img src='<%= html.html_escape(page_info.wwwprefix..page_info.staticdir) %>/tango/16x16/apps/system-users.png' height='16' width='16'> <%= name %>
	<% htmlviewfunctions.displayitemmiddle() %>
	<table><tbody>
		<tr>
			<td style='border:none;'><b><%= html.html_escape(user.value.userid.label) %></b></td>
			<td style='border:none;' width='90%'><%= html.html_escape(user.value.userid.value) %></td>
		</tr><tr>
			<td style='border:none;'><b><%= html.html_escape(user.value.username.label) %></b></td>
			<td style='border:none;'><%= html.html_escape(user.value.username.value) %></td>
		</tr><tr>
			<td style='border:none;'><b><%= html.html_escape(user.value.roles.label) %></b></td>
			<td style='border:none;'><%= html.html_escape(table.concat(user.value.roles.value, ", ")) %></td>
		</tr><tr>
			<td style='border:none;'><b><%= html.html_escape(user.value.locked.label) %></b></td>
			<td style='border:none;'><%= html.html_escape(tostring(user.value.locked.value)) %></td>
		</tr><tr>
			<td style='border:none;'><b>Option</b></td>
			<td style='border:none;'>
			<% local userid = cfe({type="hidden", value=user.value.userid.value}) %>
			<% htmlviewfunctions.displayitem(cfe({type="link", value={userid=userid, redir=redir}, label="", option="Edit", action="edituser"}), page_info, -1) %>
			<% htmlviewfunctions.displayitem(cfe({type="form", value={userid=userid}, label="", option="Delete", action="deleteuser" }), page_info, -1) %>
			<% htmlviewfunctions.displayitem(cfe({type="link", value={userid=userid}, label="", option="View Roles", action=page_info.script.."/acf-util/roles/viewuserroles"}), page_info, -1) %>
			<% if (user.value.locked.value) then htmlviewfunctions.displayitem(cfe({type="form", value={userid=userid}, label="", option="Unlock", action="unlockuser"}), page_info, -1) end %>
			</td>
		</tr>
	</tbody></table>
<%
	htmlviewfunctions.displayitemend()
end
htmlviewfunctions.displaysectionend(header_level2)
htmlviewfunctions.displaysectionend(header_level)
%>
