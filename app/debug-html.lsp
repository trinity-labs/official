<% local data, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>

<%
local header_level = htmlviewfunctions.displaysectionstart(cfe({label="Debugging"}), page_info)
local header_level2 = htmlviewfunctions.incrementheader(header_level)

htmlviewfunctions.displaysectionstart(cfe({label="View Data:"}), page_info, header_level2)
io.write(htmlviewfunctions.cfe_unpack(data))
htmlviewfunctions.displaysectionend(header_level2)

htmlviewfunctions.displaysectionstart(cfe({label="Session:"}), page_info, header_level2)
io.write(htmlviewfunctions.cfe_unpack(session))
htmlviewfunctions.displaysectionend(header_level2)

htmlviewfunctions.displaysectionstart(cfe({label="Page Info:"}), page_info, header_level2)
io.write(htmlviewfunctions.cfe_unpack(page_info))
htmlviewfunctions.displaysectionend(header_level2)

htmlviewfunctions.displaysectionend(header_level)
%>
