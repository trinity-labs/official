<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>

<%
local header_level = htmlviewfunctions.displaysectionstart(view, page_info)
local header_level2 = htmlviewfunctions.incrementheader(header_level)
%>

<% htmlviewfunctions.displaysectionstart(cfe({label="CPU Temp"}), page_info, header_level2) %>
<pre><%= html.html_escape(view.value.cpuTemp.value) %></pre>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionstart(cfe({label="Board Temp"}), page_info, header_level2) %>
<pre><%= html.html_escape(view.value.boardTemp.value) %></pre>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionend(header_level) %>