<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% format = require("acf.format") %>
<% html = require("acf.html") %>

<%
if view.value.commonnames and #view.value.commonnames.value > 1 then
	local header_level = htmlviewfunctions.displaysectionstart(view, page_info)
	local cadirs = format.string_to_table(view.value.cadir.value, "/")
	for i,v in ipairs(view.value.commonnames.value) do
		if i == #view.value.commonnames.value then break end
		print("<a href='"..page_info.script..page_info.prefix..page_info.controller.."/status?cadir="..html.html_escape(table.concat(cadirs, "/", 1, i-1)).."'> <big>"..html.html_escape(view.value.commonnames.value[i]).."</big></a> -> ")
	end
	print("<big>"..html.html_escape(view.value.commonnames.value[#view.value.commonnames.value]).."</big>")
	htmlviewfunctions.displaysectionend(header_level)
end
%>

