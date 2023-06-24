<% local view, viewlibrary, page_info, session = ... %>
<%
local viewtable = view
if view.type == "group" or view.type == "form" then
	viewtable = nil
	for name,value in pairs(view.value) do
		if value.type == "raw" then
			viewtable = value
			break
		end
	end
	if not viewtable then
		viewtable = cfe({label="error", value=view.errtxt or "Invalid stream output"})
	end
end
%>
Status: 200 OK
Content-Type: <% print(viewtable.option or "application/octet-stream") %>
<% if viewtable.length then %>
Content-Length: <%= viewtable.length %>
<% io.write("\n") %>
<% end %>
<% if viewtable.label ~= "" then %>
Content-Disposition: attachment; filename="<%= viewtable.label %>"
<% end %>
<% io.write("\n") %>
<% page_info.viewfunc(viewtable, viewlibrary, page_info, session) %>
