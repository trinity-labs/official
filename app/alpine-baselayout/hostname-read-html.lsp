<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>

<% local header_level = htmlviewfunctions.displaysectionstart(view, page_info) %>
<% htmlviewfunctions.displayitem(view) %>
<% htmlviewfunctions.displaysectionend(header_level) %>
