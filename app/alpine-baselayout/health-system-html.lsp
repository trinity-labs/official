<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>
<% json = require("json") %>
<% 
-- FORMAT UPTIME	
	local up_time = math.floor(string.match(view.value.uptime.value, "[%d]+"))
	local up_centuries = math.floor((up_time / (3600*24) / 365) / 100)
	local up_years = math.floor((up_time / (3600*24) / 365) % 100)
	local up_mounths = math.floor((((up_time / (3600 * 24)) % 365) % 365) / 30)
	local up_days = math.floor((((up_time / (3600 * 24)) % 365) % 365) % 30)
	local up_hours = string.format("%02d", math.floor((up_time % (3600 * 24)) / 3600))
	local up_minutes = string.format("%02d", math.floor(((up_time % (3600 * 24)) % 3600) / 60))
	local up_seconds = string.format("%02d", math.floor(((up_time % (3600 * 24)) % 3600) % 60))
	
-- CONVERT & DISPLAY UPTIME UP TO CENTURIES
	local uptime = up_centuries .. " Centuries " .. up_years .. " Years " .. up_mounths .. " Mounths " .. up_days .. " Days " .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"	
	if up_centuries == 1 then
		uptime = up_centuries .. " Century " .. up_years .. " Year " .. up_mounths .. " Mounths " .. up_days .. " Days " .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"
	elseif up_centuries == 0 then
		uptime =  up_years .. " Years " .. up_mounths .. " Mounths " .. up_days .. " Days " .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"
	end
	if up_years == 1 then
		uptime = up_years .. " Year " .. up_mounths .. " Mounths " .. up_days .. " Days " .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"
	elseif up_years == 0 then
		uptime = up_mounths .. " Mounths " .. up_days .. " Days " .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"
	end	
	if up_mounths == 1 then
		uptime = up_mounths .. " Mounth " .. up_days .. " Days " .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"
	elseif up_years == 0 and up_mounths == 0 then
		uptime = up_days .. " Days " .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"	
	end
	if up_days == 1 then
		uptime = up_days .. " Day " .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"
	elseif up_years == 0 and up_mounths == 0 and up_days == 0 then
		uptime = up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"	
	end
%>
<%
local header_level = htmlviewfunctions.displaysectionstart(view, page_info)
local header_level2 = htmlviewfunctions.incrementheader(header_level)
%>

<% htmlviewfunctions.displaysectionstart(cfe({label="Versions and names"}), page_info, header_level2) %>
<pre><code class="css">Alpine Linux - <%= html.html_escape(view.value.version.value) %>
<%= html.html_escape(view.value.uname.value) %></code></pre>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionstart(cfe({label="Memory"}), page_info, header_level2) %>
<pre><code><%= html.html_escape(view.value.memory.value) %></code></pre>

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
<pre><code class="js"><%= uptime %></code></pre>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionstart(cfe({label="Time/TimeZone"}), page_info, header_level2) %>
<pre><code><%= html.html_escape(view.value.date.value) %></code></pre>
<!---<pre><code><%= html.html_escape(view.value.timezone.value) %></code></pre>--->
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionend(header_level) %>
