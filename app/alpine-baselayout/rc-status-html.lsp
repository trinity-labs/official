<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>

<script type="text/javascript">
        if (typeof jQuery == 'undefined') {
                document.write('<script type="text/javascript" src="<%= html.html_escape(page_info.wwwprefix) %>/js/jquery-latest.js"><\/script>');
        }
</script>

<script type="text/javascript">
	if (typeof $.tablesorter == 'undefined') {
		document.write('<script type="text/javascript" src="<%= html.html_escape(page_info.wwwprefix) %>/js/jquery.tablesorter.js"><\/script>');
	}
</script>

<script type="text/javascript">
	$(document).ready(function() {
		$("#list").tablesorter({widgets: ['zebra']});
	});
</script>

<% htmlviewfunctions.displaycommandresults({"edit", "startstop"}, session) %>

<% local header_level = htmlviewfunctions.displaysectionstart(view, page_info) %>
<table id="list" class="tablesorter"><thead>
	<tr>
		<% if viewlibrary.check_permission("edit") or viewlibrary.check_permission("startstop") then %>
		<th>Action</th>
		<% end %>
		<th>Service Name</th>
		<th>Status</th>
		<th>Runlevels</th>
		<th>Description</th>
	</tr>
</thead><tbody>
<%
local redir = cfe({type="hidden", value=page_info.orig_action})
for i,item in ipairs(view.value) do %>
	<tr>
		<% if viewlibrary.check_permission("edit") or viewlibrary.check_permission("startstop") then %>
		<td>
		<% local servicename = cfe({type="hidden", value=item.servicename}) %>
		<% if viewlibrary.check_permission("edit") then
			htmlviewfunctions.displayitem(cfe({type="link", value={servicename=servicename, redir=redir}, label="", option="Edit", action="edit" }), page_info, -1)
		end %>
		<% if viewlibrary.check_permission("startstop") and item.actions then
			local startstopform = cfe({type="form", value={servicename=servicename}, label="", option={}, action="startstop" })
			for i,a in ipairs(item.actions) do
				startstopform.option[#startstopform.option+1] = a:gsub("^%l", string.upper)
			end
			htmlviewfunctions.displayitem(startstopform, page_info, -1)
		end %>
		</td>
		<% end %>
		<td><%= html.html_escape(item.servicename) %></td>
		<td><%= html.html_escape(item.status) %></td>
		<td><%= html.html_escape(table.concat(item.runlevels, ", ")) %>&nbsp;</td>
		<td><%= html.html_escape(item.description) %></td>
	</tr>
<% end %>
</tbody></table>
<% htmlviewfunctions.displaysectionend(header_level) %>
