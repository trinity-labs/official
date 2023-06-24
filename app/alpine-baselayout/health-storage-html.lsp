<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>

<% displaydisk = function(disk, name)
io.write('<table id="legend-title" style="margin:0px;padding:0px;border:0px;margin-top:5px;">\n')
io.write("	<tr>\n")
io.write('		<td id="legend-object" width="100px"><b>'..html.html_escape(name)..'</b></td>\n')
io.write("	</tr>\n")
io.write("</table>\n")
io.write("<pre>"..html.html_escape(disk.value).."</pre>\n")
io.write('<table class="chart-bar chart-storage">\n')
io.write("	<tr>\n")
io.write("		<td>0%</td>\n")
if tonumber(disk.used) > 0 then
	io.write('		<td id="capacity-used" class="capacity-used" width="'..html.html_escape(disk.used)..'%" style="')
	if tonumber(disk.used) < 100 then io.write('') end
	io.write('"><center><b>')
	if ( tonumber(disk.used) > 0) then io.write(html.html_escape(disk.used) .. "%") end
	io.write('</b></center></td>\n')
end
if tonumber(disk.used) < 100 then
	io.write('		<td id="capacity-free" class="capacity-free" width="'..(100-tonumber(disk.used))..'%" style="')
	if tonumber(disk.used) > 0 then io.write('') end
	io.write('"><center><b>')
	if ( 100 > tonumber(disk.used)) then io.write((100-tonumber(disk.used)) .. "%") end
	io.write('</b></center></td>\n')
end
io.write('		<td>100%</td>\n')
io.write("	</tr>\n")
io.write("</table>\n")
end %>

<%
local header_level = htmlviewfunctions.displaysectionstart(view, page_info)
local header_level2 = htmlviewfunctions.incrementheader(header_level)
%>

<% htmlviewfunctions.displaysectionstart(cfe({label="Floppy capacity"}), page_info, header_level2) %>
<% if (view.value.floppy) then
for name,floppy in pairs(view.value.floppy.value) do
	displaydisk(floppy, name)
end
else %>
<p class="error error-txt">No Floppy Mounted</p>
<% end %>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionstart(cfe({label="Harddrive capacity"}), page_info, header_level2) %>
<% if (view.value.hd) then
for name,hd in pairs(view.value.hd.value) do
	displaydisk(hd, name)
end
else %>
<p class="error error-txt">No Hard Drive Mounted</p>
<% end %>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionstart(cfe({label="RAM Disk capacity"}), page_info, header_level2) %>
<% if (view.value.ramdisk) then
for name,ramdisk in pairs(view.value.ramdisk.value) do
	displaydisk(ramdisk, name)
end
else %>
<p class="error error-txt">No RAM Disk Mounted</p>
<% end %>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% if view.value.partitions then %>
<% htmlviewfunctions.displaysectionstart(cfe({label="Disk partitions"}), page_info, header_level2) %>
<pre><%= html.html_escape(view.value.partitions.value) %></pre>
<% htmlviewfunctions.displaysectionend(header_level2) %>
<% end %>

<% htmlviewfunctions.displaysectionend(header_level) %>
