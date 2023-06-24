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
<% for i,tabl in ipairs(view.value) do %>
	<% if #tabl.jobs ~= 0 then %>
		$("#joblist<%= i %>").tablesorter({headers: {1:{sorter: false}, 2:{sorter: false}}, widgets: ['zebra']});
	<% end %>
<% end %>
	});
</script>

<% htmlviewfunctions.displaycommandresults({"editjob", "deletejob", "movejob"}, session) %>
<% htmlviewfunctions.displaycommandresults({"createjob"}, session, true) %>

<% if viewlibrary and viewlibrary.dispatch_component then
	viewlibrary.dispatch_component("status")
end %>

<%
local header_level = htmlviewfunctions.displaysectionstart(view, page_info)
local header_level2 = htmlviewfunctions.incrementheader(header_level)
local redir = cfe({type="hidden", value=page_info.orig_action})
local period = cfe({type="select", option={}})
for i,tabl in ipairs(view.value) do
	period.option[#period.option+1] = tabl.period
end
%>
<% for i,tabl in ipairs(view.value) do %>
<% htmlviewfunctions.displaysectionstart(cfe({label=tabl.period}), page_info, header_level2) %>
	<% if #tabl.jobs == 0 then %>
<p>No jobs</p>
	<% else %>
<table id="joblist<%= i %>" class="tablesorter"><thead>
	<tr>
		<th>Job</th>
		<th>Action</th>
		<th></th>
	</tr>
</thead><tbody>
		<% for i,job in ipairs(tabl.jobs) do %>
			<% local name = cfe({type="hidden", value=job}) %>
	<tr>
		<td><%= html.html_escape(string.gsub(job, "^.*/", "")) %></td>
		<td>
			<% htmlviewfunctions.displayitem(cfe({type="link", value={name=name, redir=redir}, label="", option="Edit", action="editjob" }), page_info, -1) %>
			<% htmlviewfunctions.displayitem(cfe({type="form", value={name=name}, label="", option="Delete", action="deletejob" }), page_info, -1) %>
		</td><td>
			<% period.value = tabl.period %>
			<% period.id = string.gsub(job, "^.*/", "").."period" %>
			<% htmlviewfunctions.displayitem(cfe({type="form", value={name=name, period=period}, label="", option="Move", action="movejob" }), page_info, -1) %>
		</td>
	</tr>
		<% end %>
</tbody></table>
	<% end %>
<% htmlviewfunctions.displaysectionend(header_level2) %>
<% end %>
<% htmlviewfunctions.displaysectionend(header_level) %>

<% if viewlibrary.check_permission("createjob") then
	viewlibrary.dispatch_component("createjob")
end %>
