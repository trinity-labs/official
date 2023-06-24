<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>
<% json = require("json") %>

<%
local header_level = htmlviewfunctions.displaysectionstart(view, page_info)
local header_level2 = htmlviewfunctions.incrementheader(header_level)
%>

<% htmlviewfunctions.displaysectionstart(cfe({label="Versions and names"}), page_info, header_level2) %>
<pre><%= html.html_escape(view.value.version.value) %></pre>
<pre><code><%= html.html_escape(view.value.uname.value) %></code></pre>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionstart(cfe({label="Memory"}), page_info, header_level2) %>
<pre><%= html.html_escape(view.value.memory.value) %></pre>

<%
local function print_percent(val)
	if (tonumber(val) > 0) then
		io.write(html.html_escape(val) .. "%")
	end
end
%>

<table class="chart-bar chart-memory" style="margin:0px;padding:0px;border:0px">
	<tr>
		<td>0%</td>
		<td id="capacity-used" class="capacity-used" width="<%= html.html_escape(view.value.memory.used) %>%">
			<center><b><% print_percent(view.value.memory.used) %></b></center>
		</td>
		<td id="capacity-buffered" class="capacity-buffered" width="<%= html.html_escape(view.value.memory.buffers) %>%">
			<center><b><% print_percent(view.value.memory.buffers) %></b></center>
		</td>
		<td id="capacity-free" class="capacity-free" width="<%= tonumber(view.value.memory.free) %>%">
		<% print_percent(view.value.memory.free) %>
		</td>
		<td>100%</td>
	</tr>
</table>

<div class="chart-bar chart-legend" style="margin:0px;padding:0px;border:0px;margin-top:5px">
		<p id="legend" width="100px"><b>Legend</b> :</p>
		<p id="legend-used" class="capacity-used" width="20px"></p>
		<p width="70px"><b>= Used</b></p>
		<p id="legend-buffered" class="capacity-buffered"></p>
		<p width="70px"><b>= Buffers/Cached</b><p>
		<p id="legend-free" class="capacity-free"></p>
		<p width="70px"><b>= Free</b></p>
</div>

<% htmlviewfunctions.displaysectionstart(cfe({label="Uptime"}), page_info, header_level2) %>
<pre><%= html.html_escape(view.value.uptime.value) %></pre>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionstart(cfe({label="Time/TimeZone"}), page_info, header_level2) %>
<pre><%= html.html_escape(view.value.date.value) %></pre>
<!---<pre><%= html.html_escape(view.value.timezone.value) %></pre>--->
<% htmlviewfunctions.displaysectionend(header_level2) %>



<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionend(header_level) %>
