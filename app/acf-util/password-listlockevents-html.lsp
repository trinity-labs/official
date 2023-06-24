<% local view, viewlibrary, page_info, session = ...
htmlviewfunctions = require("htmlviewfunctions")
html = require("acf.html")
%>

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
	if (typeof $.tablesorter.regex.ipv4Validate == 'undefined') {
		document.write('<script type="text/javascript" src="<%= html.html_escape(page_info.wwwprefix) %>/js/parsers/parser-network.js"><\/script>');
	}
</script>

<script type="text/javascript">
	$(document).ready(function() {
		$("#list").tablesorter({widgets: ['zebra']});
	});
</script>


<% htmlviewfunctions.displaycommandresults({"unlockuser", "unlockip"}, session, true) %>

<% local header_level = htmlviewfunctions.displaysectionstart(view, page_info) %>
<table id="list" class="tablesorter"><thead>
	<tr>
		<th>User ID</th>
		<th>IP Address</th>
		<th>Time</th>
	</tr>
</thead><tbody>
<% for i,lock in ipairs( view.value ) do %>
	<tr>
		<td><%= html.html_escape(lock.userid) %></td>
		<td><%= html.html_escape(lock.ip) %></td>
		<td><%= format.formattime(lock.time) %></td>
	</tr>
<% end %>
</tbody></table>
<% htmlviewfunctions.displaysectionend(header_level) %>

<% if viewlibrary and viewlibrary.dispatch_component then
	viewlibrary.dispatch_component("unlockuser")
	viewlibrary.dispatch_component("unlockip")
end %>
