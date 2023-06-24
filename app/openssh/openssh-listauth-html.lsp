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
		$("#list").tablesorter({headers: {0:{sorter: false}}, widgets: ['zebra']});
	});
</script>

<% htmlviewfunctions.displaycommandresults({"deleteauth"}, session) %>
<% htmlviewfunctions.displaycommandresults({"addauth"}, session, true) %>

<% local header_level = htmlviewfunctions.displaysectionstart(cfe({label="Authorized Keys for "..view.value.user.value}), page_info) %>
<table id="list" class="tablesorter"><thead>
	<tr>
		<th>Action</th>
		<th>ID</th>
		<th>Key</th>
	</tr>
</thead><tbody>
<% local user = cfe({ type="hidden", value=view.value.user.value }) %>
<% local authid = cfe({ type="hidden", value="" }) %>
<% for i,auth in ipairs(view.value.auth.value) do %>
	<tr>
		<td>
		<% authid.value = auth.id %>
		<% htmlviewfunctions.displayitem(cfe({type="form", value={user=user, auth=authid}, label="", option="Delete", action="deleteauth"}), page_info, -1) %>
		</td>
		<td><%= html.html_escape(auth.id) %></td>
		<td><% if #auth.key>32 then io.write(html.html_escape(string.sub(auth.key,0,16)) .. "  ...  " .. html.html_escape(string.sub(auth.key, -16))) else io.write(html.html_escape(auth.key)) end %></td>
	</tr>
<% end %>
</tbody></table>
<p>In order to preserve keys with lbu, you must add /<% if view.value.user.value ~= "root" then io.write("home/") end %><%= view.value.user.value %>/.ssh/authorized_keys to lbu include
<% htmlviewfunctions.displaysectionend(header_level) %>

<% viewlibrary.dispatch_component("addauth", {user=view.value.user.value}) %>
