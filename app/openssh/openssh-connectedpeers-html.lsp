<% local data, viewlibrary, page_info, session = ...
htmlviewfunctions = require("htmlviewfunctions")
html = require("acf.html")
%>

<% local header_level = htmlviewfunctions.displaysectionstart(data, page_info) %>
<% local header_level2 = htmlviewfunctions.incrementheader(header_level) %>
<%
if #data.value == 0 then
	io.write("<p>No peers found</p>\n")
end
local col1="180px"
for k,v in pairs(data.value) do
	local label = v.host
	if v.name and v.name ~= v.host then label = label.." - "..html.html_escape(v.name) end
	htmlviewfunctions.displaysectionstart(cfe({label=label}), page_info, header_level2)
	io.write("<table>")
	for i=1, v.cnt do
		io.write("<tr>")
		if (v.tty[i]) then
			io.write("<td width='20px' style='padding-left:20px;vertical-align:top;'><img src='".. html.html_escape(page_info.wwwprefix..page_info.staticdir) .. "/tango/16x16/apps/utilities-terminal.png' height='16' width='16'></td>")
			io.write("<td style='padding-bottom:10px'>\n")
			io.write("<table>")
			io.write("<tr><td width='"..col1.."' style='font-weight:bold;'>Session user:</td><td>".. html.html_escape(v.tty[i].user) .. "</td></tr>\n")
			io.write("<tr><td width='"..col1.."' style='font-weight:bold;'>Session TTY:</td><td>".. html.html_escape(v.tty[i].tty) .. "</td></tr>\n")

			io.write("</table>")
			io.write("</td>\n")

		else
			io.write("<td width='20px' style='padding-left:20px;vertical-align:top;'><img src='".. html.html_escape(page_info.wwwprefix..page_info.staticdir) .. "/tango/16x16/emblems/emblem-unreadable.png' height='16' width='16'></td>")
			io.write("<td style='padding-bottom:10px'>\n")
			io.write("<table>")
			io.write("<tr><td width='"..col1.."' style='font-weight:bold;'>Session user:</td><td>No records</td></tr>\n")
			io.write("<tr><td width='"..col1.."' style='font-weight:bold;'>Session TTY:</td><td>No records</td></tr>\n")
			io.write("<tr><td width='"..col1.."' style='font-weight:bold;'>Other:</td><td>This could be a sshfs session</td></tr>\n")

			io.write("</table>")
			io.write("</td>\n")
		end
		io.write("</tr>")
	end
	io.write("</table>")
	htmlviewfunctions.displaysectionend(header_level2)
end
%>
<% htmlviewfunctions.displaysectionend(header_level) %>
