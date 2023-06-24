<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>

<%
if viewlibrary and viewlibrary.dispatch_component and viewlibrary.check_permission("getcachain") and page_info.orig_action == page_info.prefix..page_info.controller.."/"..page_info.action then
	viewlibrary.dispatch_component("getcachain", {cadir=view.value.cadir.value})
end
%>

<% local header_level = htmlviewfunctions.displaysectionstart(view, page_info) %>
<pre><%= html.html_escape(view.value.details.value.value) %></pre>
<% htmlviewfunctions.displaysectionend(header_level) %>
