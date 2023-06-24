<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>

<% htmlviewfunctions.displaycommandresults({"checkenvironment", "putcacert", "generatecacert"}, session, true) %>
<% htmlviewfunctions.displaycommandresults({"install"}, session) %>

<%
if viewlibrary and viewlibrary.dispatch_component and viewlibrary.check_permission("getcachain") and page_info.orig_action == page_info.prefix..page_info.controller.."/"..page_info.action then
	viewlibrary.dispatch_component("getcachain", {cadir=view.value.cadir.value})
end
%>

<%
local header_level = htmlviewfunctions.displaysectionstart(view, page_info)

htmlviewfunctions.displayitem(view.value.version)
if view.value.version and view.value.version.errtxt and viewlibrary.check_permission("apk-tools/apk/install") then
        local install = cfe({ type="form", value={}, label="Install package", option="Install", action=page_info.script.."/apk-tools/apk/install" })
        install.value.package = cfe({ type="hidden", value=view.value.version.name })
        htmlviewfunctions.displayitem(install, page_info, 0)    -- header_level 0 means display inline without header
end

htmlviewfunctions.displayitem(view.value.conffile)
htmlviewfunctions.displayitem(view.value.environment)
htmlviewfunctions.displayitem(view.value.cacert)
htmlviewfunctions.displayitem(view.value.cakey)
%>

<%
if not view.value.version.errtxt and not view.value.conffile.errtxt then
	if view.value.environment.errtxt then
		if viewlibrary and viewlibrary.dispatch_component and viewlibrary.check_permission("checkenvironment") then
			viewlibrary.dispatch_component("checkenvironment", {cadir=view.value.cadir.value})
		end
	elseif not view.value.cacert.errtxt and not view.value.cakey.errtxt then
		htmlviewfunctions.displaysectionstart(view.value.cacertcontents, page_info, header_level)
		print("<pre>"..html.html_escape(view.value.cacertcontents.value).."</pre>")
		htmlviewfunctions.displaysectionend(header_level)
	elseif viewlibrary and viewlibrary.dispatch_component then
		if viewlibrary.check_permission("putcacert") then
			viewlibrary.dispatch_component("putcacert", {cadir=view.value.cadir.value})
		end
		if viewlibrary.check_permission("generatecacert") then
			viewlibrary.dispatch_component("generatecacert", {cadir=view.value.cadir.value})
		end
	end
end
%>

<%
if not view.value.cacert.errtxt and viewlibrary.check_permission("downloadcacert") then
	local viewtype = cfe({type="hidden", value="stream"})
	local cadir = cfe({type="hidden", value=view.value.cadir.value})
        htmlviewfunctions.displaysectionstart(cfe({label="Download CA Cert"}), page_info, header_level)
        htmlviewfunctions.displayitem(cfe({type="link", value={certtype=cfe({type="hidden", value="PEM"}), viewtype=viewtype, cadir=cadir}, label="", option="Download PEM", action="downloadcacert"}), page_info, -1)
        htmlviewfunctions.displayitem(cfe({type="link", value={certtype=cfe({type="hidden", value="DER"}), viewtype=viewtype, cadir=cadir}, label="", option="Download DER", action="downloadcacert"}), page_info, -1)
        htmlviewfunctions.displaysectionend(header_level)
end
%>
