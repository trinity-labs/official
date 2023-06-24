<% local view, viewlibrary, page_info, session  = ... %>
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
	<% if viewlibrary.check_permission("delete") then %>
		$("#list").tablesorter({headers: {1:{sorter: false}, 2:{sorter: false}, 3:{sorter: false}}, widgets: ['zebra']});
	<% else %>
		$("#list").tablesorter({headers: {0:{sorter: false}, 1:{sorter: false}, 2:{sorter: false}}, widgets: ['zebra']});
	<% end %>
	});
</script>

<% htmlviewfunctions.displaycommandresults({"delete"}, session) %>

<% local header_level = htmlviewfunctions.displaysectionstart(view, page_info) %>
<table id="list" class="tablesorter"><thead>
	<tr>
	<% if viewlibrary.check_permission("delete") then %>
		<th>Delete</th>
	<% end %>
		<th>View</th>
		<th>Tail</th>
		<th>Save</th>
		<th>Size</th>
		<th>Last Modified</th>
		<th>File</th>
	</tr>

</thead><tbody>
<% local viewtype = cfe({type="hidden", value="stream"}) %>
<% for i,file in ipairs(view.value) do %>
	<% local filename = cfe({type="hidden", value=file.filename}) %>
	<tr>
	<% if viewlibrary.check_permission("delete") then %>
		<td>
		<% if file.inuse then %>
			in use
		<% else
			htmlviewfunctions.displayitem(cfe({type="form", value={filename=filename}, label="", option="Delete", action="delete" }), page_info, -1)
		end %>
		</td>
	<% end %>
		<td><% htmlviewfunctions.displayitem(cfe({type="link", value={filename=filename}, label="", option="View", action="view" }), page_info, -1) %></td>
		<td><% htmlviewfunctions.displayitem(cfe({type="link", value={filename=filename}, label="", option="Tail", action="tail" }), page_info, -1) %></td>
		<td><% htmlviewfunctions.displayitem(cfe({type="link", value={filename=filename, viewtype=viewtype}, label="", option="Download", action="download" }), page_info, -1) %></td>
		<td><span class="hide"><%= html.html_escape(file.size) %>b</span><%= format.formatfilesize(file.size) %></td>
		<td><%= format.formattime(file.mtime) %></td>
		<td><%= html.html_escape(file.filename) %></td>
	</tr>
<% end %>
</tbody></table>
<% htmlviewfunctions.displaysectionend(header_level) %>
