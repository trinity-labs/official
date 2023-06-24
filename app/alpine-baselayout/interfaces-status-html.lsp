<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>

<%
local header_level = htmlviewfunctions.displaysectionstart(view, page_info)
htmlviewfunctions.displayitem(view.value.filename)
htmlviewfunctions.displayitem(view.value.ipaddr)
htmlviewfunctions.displayitem(view.value.iproute)
if view.value.iptunnel.value ~= "" then
	htmlviewfunctions.displayitem(view.value.iptunnel)
end
htmlviewfunctions.displaysectionend(header_level)
%>
