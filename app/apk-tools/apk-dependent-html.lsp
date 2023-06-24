<% local form, viewlibrary, page_info, session = ... %>
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
		document.write('<script type="text/javascript" src="<%= html.html_escape(page_info.wwwprefix) %>/js/jquery.tablesorter.widgets.js"><\/script>');
		document.write('<link href="<%= html.html_escape(page_info.wwwprefix..page_info.staticdir) %>/tablesorter/jquery.tablesorter.pager.css" rel="stylesheet">');
		document.write('<script type="text/javascript" src="<%= html.html_escape(page_info.wwwprefix) %>/js/widgets/widget-pager.js"><\/script>');
	}
</script>
	
<script type="text/javascript">
	$(document).ready(function() {
<% if viewlibrary.check_permission("install") or viewlibrary.check_permission("upgrade") or viewlibrary.check_permission("details") then %>
		// The following is a hack to include a multiline string
		var MultiString = function(f) {
			return f.toString().split('\n').slice(1, -1).join('\n');
		}
		var <%= page_info.action %>actions = MultiString(function() {/**
		<%
			local packagecfe = cfe({ type="hidden", value="REPLACEME" })
			if viewlibrary.check_permission("delete") and page_info.action == "toplevel" then
				htmlviewfunctions.displayitem(cfe({type="form", value={package=packagecfe}, label="", option="Delete", action="delete" }), page_info, -1)
			end
			if viewlibrary.check_permission("install") then
				if page_info.action == "dependent" then
					htmlviewfunctions.displayitem(cfe({type="form", value={package=packagecfe}, label="", option="Promote", action="install" }), page_info, -1)
				elseif page_info.action ~= "toplevel" then
					htmlviewfunctions.displayitem(cfe({type="form", value={package=packagecfe}, label="", option="Install", action="install" }), page_info, -1)
				end
			end
			if viewlibrary.check_permission("upgrade") then
				htmlviewfunctions.displayitem(cfe({type="form", value={package=packagecfe}, label="", option="Upgrade", action="upgrade" }), page_info, -1)
			end
			if viewlibrary.check_permission("details") then
				htmlviewfunctions.displayitem(cfe({type="form", value={package=packagecfe}, label="", option="View", action="details" }), page_info, -1)
			end
		%>
		**/});
<% end %>

                $("#<%= page_info.action %>list").tablesorter({widgets: ['zebra', 'filter', 'pager'], widgetOptions: {
			pager_selectors: { container: '#<%= page_info.action %>pager' },
			// Filtering is handled by the server
			filter_serversideFiltering: true,

			// We can put the page number and size here, filtering and sorting handled by pager_customAjaxUrl
			pager_ajaxUrl : '<%= html.html_escape(page_info.script..page_info.prefix..page_info.controller.."/"..page_info.action) %>?viewtype=json&page={page+1}&pagesize={size}',

			// Modify the url after all processing has been applied to handle filtering and sorting
			pager_customAjaxUrl: function(table, url) {
<% if viewlibrary.check_permission("install") or viewlibrary.check_permission("upgrade") or viewlibrary.check_permission("details") then %>
				var columns = ["upgrade", "name", "version"];
<% else %>
				var columns = ["name", "version"];
<% end %>
				var directions = ["asc", "desc"];
				for (var s=0; s<table.config.sortList.length; s++) {
					// 0=column number, 1=direction(0 is asc)
					if ((table.config.sortList[s][0] < columns.length) && (table.config.sortList[s][1] < directions.length)) {
						url += "&orderby."+(s+1)+".column="+columns[table.config.sortList[s][0]]+"&orderby."+(s+1)+".direction="+directions[table.config.sortList[s][1]]
					}
				}
				for (var f=0; f<table.config.pager.currentFilters.length; f++) {
					var filter = table.config.pager.currentFilters[f];
					if (filter.trim()) {
						url += "&filter."+columns[f]+"="+encodeURIComponent(filter.trim());
					}
				}
				return url;
			},

			// process ajax so that the following information is returned:
			// [ total_rows (number), rows (array of arrays), headers (array; optional) ]
			pager_ajaxProcessing: function(data){
				if (data && data.value && data.value.result) {
					rows = [];
					for ( r=0; r<data.value.result.value.length; r++) {
						row=[];
<% if viewlibrary.check_permission("install") or viewlibrary.check_permission("upgrade") or viewlibrary.check_permission("details") then %>
						var tmp = <%= page_info.action %>actions.replace(/REPLACEME/g, data.value.result.value[r].name);
						if (data.value.result.value[r].upgrade) {
<% if page_info.action ~= "dependent" and page_info.action ~= "toplevel" then %>
							row[0] = tmp.replace(/action="install"[\s\S]*?<form /, "");
<% else %>
							row[0] = tmp;
<% end %>
						} else {
							row[0] = tmp.replace(/action="upgrade"[\s\S]*?<form /, "");
						}
						row[1] = data.value.result.value[r].name;
						row[2] = data.value.result.value[r].version;
<% else %>
						row[0] = data.value.result.value[r].name;
						row[1] = data.value.result.value[r].version;
<% end %>
						rows.push(row);
					}
					return [ parseInt(data.value.rowcount.value), rows];
				}
			}
		}});
	});
</script>

<% htmlviewfunctions.displaycommandresults({"delete", "install", "upgrade"}, session) %>

<% local header_level = htmlviewfunctions.displaysectionstart(form, page_info) %>
<table id="<%= page_info.action %>list" class="tablesorter"><thead>
	<tr>
	<% if viewlibrary.check_permission("install") or viewlibrary.check_permission("upgrade") or viewlibrary.check_permission("details") then %>
		<th class="filter-false remove">Action</th>
	<% end %>
		<th>Package Name</th>
		<th>Version</th>
	</tr>
</thead><tbody>
</tbody></table>

<div id="<%= page_info.action %>pager" class="pager">
	<form>
		Page: <select class="gotoPage"></select>
		<img src="<%= html.html_escape(page_info.wwwprefix..page_info.staticdir) %>/tablesorter/first.png" class="first"/>
		<img src="<%= html.html_escape(page_info.wwwprefix..page_info.staticdir) %>/tablesorter/prev.png" class="prev"/>
		<span class="pagedisplay"></span> <!-- this can be any element, including an input -->
		<img src="<%= html.html_escape(page_info.wwwprefix..page_info.staticdir) %>/tablesorter/next.png" class="next"/>
		<img src="<%= html.html_escape(page_info.wwwprefix..page_info.staticdir) %>/tablesorter/last.png" class="last"/>
		<select class="pagesize">
			<option selected="selected" value="10">10</option>
			<option value="20">20</option>
			<option value="30">30</option>
			<option value="40">40</option>
		</select>
	</form>
</div>

<% htmlviewfunctions.displaysectionend(header_level) %>
