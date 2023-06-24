<% local view, viewlibrary, page_info, session = ... %>
Status: 200 OK
CacheControl: no-store
Pragma: no-cache
Expires: -1
Content-Type: "application/json"
<% io.write("\n") %>
<% page_info.viewfunc(view, viewlibrary, page_info, session) %>
