<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>

<% displaydisk = function(disk, name)
io.write("<pre>"..html.html_escape(disk.value).."</pre>\n")
io.write('<table style="margin:0px;padding:0px;border:0px">\n')
io.write("	<tr>\n")
io.write("		<td>0%</td>\n")
if tonumber(disk.used) > 0 then
	io.write('		<td width="'..html.html_escape(disk.used)..'%" style="background:red;border:2px solid black;')
	if tonumber(disk.used) < 100 then io.write('border-right:none;') end
	io.write('"><center><b>')
	if ( tonumber(disk.used) > 10) then io.write(html.html_escape(disk.used) .. "%") end
	io.write('</b></center></td>\n')
end
if tonumber(disk.used) < 100 then
	io.write('		<td width="'..(100-tonumber(disk.used))..'%" style="background:#0c0;border:2px solid black;')
	if tonumber(disk.used) > 0 then io.write('border-left:none;') end
	io.write('"><center><b>')
	if ( 90 > tonumber(disk.used)) then io.write((100-tonumber(disk.used)) .. "%") end
	io.write('</b></center></td>\n')
end
io.write('		<td>100%</td>\n')
io.write("	</tr>\n")
io.write("</table>\n")
io.write('<table style="margin:0px;padding:0px;border:0px;margin-top:5px;">\n')
io.write("	<tr>\n")
io.write('		<td width="100px"><b>'..html.html_escape(name)..'</b></td><td style="background:red;border:2px solid black;" width="20px"></td><td width="70px"><b>=Used</b></td><td style="background:#0c0;border:2px solid black;" width="20px"></td><td><b>=Free</b></td>\n')
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
<p>No Floppy mounted</p>
<% end %>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionstart(cfe({label="Harddrive capacity"}), page_info, header_level2) %>
<% if (view.value.hd) then
for name,hd in pairs(view.value.hd.value) do
	displaydisk(hd, name)
end
else %>
<p>No Harddrive mounted</p>
<% end %>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% htmlviewfunctions.displaysectionstart(cfe({label="RAM Disk capacity"}), page_info, header_level2) %>
<% if (view.value.ramdisk) then
for name,ramdisk in pairs(view.value.ramdisk.value) do
	displaydisk(ramdisk, name)
end
else %>
<p>No RAM Disk mounted</p>
<% end %>
<% htmlviewfunctions.displaysectionend(header_level2) %>

<% if view.value.partitions then %>
<% htmlviewfunctions.displaysectionstart(cfe({label="Disk partitions"}), page_info, header_level2) %>
<pre><%= html.html_escape(view.value.partitions.value) %></pre>
<% htmlviewfunctions.displaysectionend(header_level2) %>
<% end %>

<% htmlviewfunctions.displaysectionend(header_level) %>
