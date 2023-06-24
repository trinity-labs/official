<% local form, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>

<% if viewlibrary and viewlibrary.dispatch_component then
	viewlibrary.dispatch_component("status")
end %>

<%
local header_level = htmlviewfunctions.displaysectionstart(form, page_info)
local header_level2 = htmlviewfunctions.incrementheader(header_level)

form.action = page_info.script .. page_info.prefix .. page_info.controller .. "/" .. page_info.action
htmlviewfunctions.displayformstart(form, page_info)
htmlviewfunctions.displaysectionstart(cfe({label="General"}), page_info, header_level2)
	htmlviewfunctions.displayformitem(form.value.logfile, "logfile")
	htmlviewfunctions.displayformitem(form.value.loglevel, "loglevel")
	htmlviewfunctions.displayformitem(form.value.smallerlogs, "smallerlogs")
htmlviewfunctions.displaysectionend(header_level2)
htmlviewfunctions.displaysectionstart(cfe({label="Log Rotate"}), page_info, header_level2)
	htmlviewfunctions.displayformitem(form.value.maxsize, "maxsize")
	htmlviewfunctions.displayformitem(form.value.numrotate, "numrotate")
htmlviewfunctions.displaysectionend(header_level2)
htmlviewfunctions.displaysectionstart(cfe({label="Remote Logging"}), page_info, header_level2)
	htmlviewfunctions.displayformitem(form.value.localandnetworklog, "localandnetworklog")
	htmlviewfunctions.displayformitem(form.value.remotelogging, "remotelogging")
htmlviewfunctions.displaysectionend(header_level2)
htmlviewfunctions.displayformend(form)
htmlviewfunctions.displaysectionend(header_level)
%>
