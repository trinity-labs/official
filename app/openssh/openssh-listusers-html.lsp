<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>

<% local header_level = htmlviewfunctions.displaysectionstart(cfe({label="System User Accounts"}), page_info) %>
<% for i,user in ipairs(view.value) do %>
	<% htmlviewfunctions.displayitemstart() %>
	<img src='<%= html.html_escape(page_info.wwwprefix..page_info.staticdir) %>/tango/16x16/apps/system-users.png' height='16' width='16'> <%= html.html_escape(user) %>
	<% htmlviewfunctions.displayitemmiddle() %>
	<% htmlviewfunctions.displayitem(cfe({type="link", value={user=cfe({type="hidden", value=user})}, label="", option="Edit", action="listauth"}), page_info, -1) %>
	<% htmlviewfunctions.displayitemend() %>
<% end %>
<% htmlviewfunctions.displaysectionend(header_level) %>
