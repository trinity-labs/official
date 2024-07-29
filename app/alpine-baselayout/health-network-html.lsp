<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>

<%
local header_level = htmlviewfunctions.displaysectionstart(view, page_info)
local header_level2 = htmlviewfunctions.incrementheader(header_level)
%>

<% htmlviewfunctions.displaysectionstart(cfe({label="Interface status"}), page_info, header_level2) %>
<pre><code><%= html.html_escape(view.value.interfaces.value) %></code></pre>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionstart(cfe({label="Routes"}), page_info, header_level2) %>
<pre><code><%= html.html_escape(view.value.routes.value) %></code></pre>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% if view.value.tunnel.value ~= "" then %>
<% htmlviewfunctions.displaysectionstart(cfe({label="Tunnels"}), page_info, header_level2) %>
<pre><code><%= html.html_escape(view.value.tunnel.value) %></code></pre>
<% htmlviewfunctions.displaysectionend(header_level2) %>
<% end %>

<% htmlviewfunctions.displaysectionend(header_level) %>
