<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>

<%
local header_level = htmlviewfunctions.displaysectionstart(view, page_info)
local header_level2 = htmlviewfunctions.incrementheader(header_level)
%>

<% htmlviewfunctions.displaysectionstart(cfe({label="CPU Temp"}), page_info, header_level2) %>
<pre><code>Processor Temperature:  <%= html.html_escape(math.ceil(tonumber(view.value.cpuTemp.value / 1000))) %> °C</code></pre>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionstart(cfe({label="Board Temp"}), page_info, header_level2) %>
<pre><code>Motherboard Temperature:  <%= html.html_escape(math.ceil(tonumber(view.value.boardTemp.value / 1000))) %> °C</code></pre>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionend(header_level) %>