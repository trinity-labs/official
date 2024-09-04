<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>

<%
local header_level = htmlviewfunctions.displaysectionstart(view, page_info)
local header_level2 = htmlviewfunctions.incrementheader(header_level)
%>

<% htmlviewfunctions.displaysectionstart(cfe({label="CPU Model"}), page_info, header_level2) %>
<pre><code><%= html.html_escape(view.value.model.value) %></code></pre>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionstart(cfe({label="Processor"}), page_info, header_level2) %>
<pre><code><%= html.html_escape(view.value.processor.value) %></code></pre>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionstart(cfe({label="Memory"}), page_info, header_level2) %>
<pre><code><%= html.html_escape(view.value.memory.value) %></code></pre>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionend(header_level) %>