<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>

<%
local header_level = htmlviewfunctions.displaysectionstart(cfe({label="Modules"}), page_info)
local header_level2 = htmlviewfunctions.displaysectionstart(cfe({label="Installed modules"}), page_info, htmlviewfunctions.incrementheader(header_level))
%>
<pre><code><%= html.html_escape(view.value) %></code></pre>
<%
htmlviewfunctions.displaysectionend(header_level2)
htmlviewfunctions.displaysectionend(header_level)
%>
