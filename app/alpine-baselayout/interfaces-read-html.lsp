<% local view, viewlibrary, page_info, session = ...
htmlviewfunctions = require("htmlviewfunctions")
html = require("acf.html")
%>

<% showoption = function(option)
	if option.errtxt or option.value ~= "" then %>
		<tr><td width='120px' style='font-weight:bold;border:none;'><%= html.html_escape(option.label) %></td>
		<td style='border:none;'<% if option.errtxt then io.write("class='error'") end %>>
		<%= string.gsub(html.html_escape(tostring(option.value)), "\n", "<br/>") %>
		<% if option.errtxt then io.write("<br/>"..html.html_escape(option.errtxt)) end %>
		</td></tr>
	<% end %>
<% end %>

<% htmlviewfunctions.displaycommandresults({"update", "delete", "ifup", "ifdown", "restart"}, session) %>

<% if viewlibrary and viewlibrary.dispatch_component then
	viewlibrary.dispatch_component("status")
end %>

<% local redir = cfe({type="hidden", value=page_info.orig_action}) %>
<% local header_level = htmlviewfunctions.displaysectionstart(view, page_info) %>
<% for i,entry in ipairs(view.value) do
	local interface = entry.value
	htmlviewfunctions.displayitemstart()
	%>
	<span class="interface-name"><%= html.html_escape(interface.name.value) %></span>
	<% htmlviewfunctions.displayitemmiddle() %>
	<table style='margin-bottom:10px'>

	<%
	showoption(interface.family)
	if interface.method then showoption(interface.method) end
	for name,option in pairs(interface) do
		if name~="name" and name~="family" and name~="method" then
			showoption(option)
		end
	end %>
	
<!--REVERSE INPUT AND INFO - 20231903-->
	
	<% if viewlibrary.check_permission("update") or viewlibrary.check_permission("delete") or viewlibrary.check_permission("ifup") or viewlibrary.check_permission("ifdown") then %>
		<% local name = cfe({type="hidden", value=interface.name.value}) %>
	<tr><td colspan=2 style='border:none;'>
	<% if viewlibrary.check_permission("update") then
		htmlviewfunctions.displayitem(cfe({type="link", value={name=name, redir=redir}, label="", option="Edit", action="update" }), page_info, -1)
	end
	if viewlibrary.check_permission("delete") then
		htmlviewfunctions.displayitem(cfe({type="form", value={name=name}, label="", option="Delete", action="delete" }), page_info, -1)
	end
	if viewlibrary.check_permission("ifup") then
		htmlviewfunctions.displayitem(cfe({type="form", value={name=name}, label="", option="ifup", action="ifup" }), page_info, -1)
	end
	if viewlibrary.check_permission("ifdown") then
		htmlviewfunctions.displayitem(cfe({type="form", value={name=name}, label="", option="ifdown", action="ifdown" }), page_info, -1)
	end %>
	</td></tr>
	<% end %>
	</table>
	<% htmlviewfunctions.displayitemend() %>
<% end %>
<% htmlviewfunctions.displaysectionend(header_level) %>

<% if viewlibrary and viewlibrary.dispatch_component then
	viewlibrary.dispatch_component("restart")
end %>
