<% local form, viewlibrary, page_info = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>

<%
local header_level0, header_level, header_level2
if form.type == "form" then
	header_level0 = htmlviewfunctions.displaysectionstart(cfe({label="Configuration"}), page_info)
	header_level = htmlviewfunctions.displaysectionstart(cfe({label="Expert Configuration"}), page_info, htmlviewfunctions.incrementheader(header_level0))
else
	header_level = htmlviewfunctions.displaysectionstart(cfe({label="View File"}), page_info)
end
htmlviewfunctions.displayinfo(form)
header_level2 = htmlviewfunctions.displaysectionstart(cfe({label="File Details"}), page_info, htmlviewfunctions.incrementheader(header_level))

htmlviewfunctions.displayitem(form.value.filename)
htmlviewfunctions.displayitem(form.value.size)
htmlviewfunctions.displayitem(form.value.mtime)
if form.value.grep and form.value.grep.value and form.value.grep.value ~= "" then
	htmlviewfunctions.displayitem(form.value.grep)
end

htmlviewfunctions.displaysectionend(header_level2)

if form.value.filecontent then
	htmlviewfunctions.displaysectionstart(cfe({label="File Content"}), page_info, header_level2)
	if form.type == "form" then
		htmlviewfunctions.displayformstart(form, page_info)
		form.value.filename.type = "hidden"
		for name,value in pairs(form.value) do
			if value.type == "hidden" then
				htmlviewfunctions.displayformitem(value, name)
			end
		end
	end
%>
<textarea name="filecontent">
<%= html.html_escape(form.value.filecontent.value) %>
</textarea>
<%
	htmlviewfunctions.displayinfo(form.value.filecontent)

	if form.type == "form" then
		htmlviewfunctions.displayformend(form)
	end
	htmlviewfunctions.displaysectionend(header_level2)
end

htmlviewfunctions.displaysectionend(header_level)
if form.type == "form" then
	htmlviewfunctions.displaysectionend(header_level0)
end
%>
