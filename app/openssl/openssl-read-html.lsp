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
		$("#pending").tablesorter({headers: {0:{sorter: false}}, widgets: ['zebra']});
		$("#approved").tablesorter({headers: {0:{sorter: false}, 5:{sorter:'usLongDate'}}, widgets: ['zebra']});
		$("#revoked").tablesorter({headers: {0:{sorter: false}, 5:{sorter:'usLongDate'}}, widgets: ['zebra']});
	});
</script>

<% htmlviewfunctions.displaycommandresults({"approve", "deleterequest", "deletemyrequest", "renewcert", "requestrenewcert", "revoke", "deletecert"}, session) %>

<%
if viewlibrary and viewlibrary.dispatch_component and viewlibrary.check_permission("getcachain") and page_info.orig_action == page_info.prefix..page_info.controller.."/"..page_info.action then
	viewlibrary.dispatch_component("getcachain", {cadir=view.value.cadir.value})
end
%>

<% local cadir = cfe({ type="hidden", value=view.value.cadir.value }) %>
<%
local label = ""
if view.value.user then
	label = label.." for "..html.html_escape(view.value.user.value)
end
local header_level = htmlviewfunctions.displaysectionstart(cfe({label="Pending certificate requests"..label}), page_info)
%>
<% if not view.value.pending or #view.value.pending.value == 0 then %>
	<p>No certificates pending</p>
<% else %>
<table id="pending" class="tablesorter">
<thead>
	<tr>
		<th>Action</th>
		<th>User</th>
		<th>Cert Type</th>
		<th>Common Name</th>
	</tr>
</thead>
<tbody>
	<% local req = cfe({ type="hidden", value="" }) %>
	<% for i,request in ipairs(view.value.pending.value) do %>
		<tr>
		<td>
		<%
		req.value = request.request
		if viewlibrary.check_permission("viewrequest") then
			htmlviewfunctions.displayitem(cfe({type="link", value={request=req, cadir=cadir}, label="", option="View", action="viewrequest"}), page_info, -1)
		end
		if viewlibrary.check_permission("approve") then
			htmlviewfunctions.displayitem(cfe({type="form", value={request=req, cadir=cadir}, label="", option="Approve", action="approve"}), page_info, -1)
		end
		if viewlibrary.check_permission("deleterequest") then
			htmlviewfunctions.displayitem(cfe({type="form", value={request=req, cadir=cadir}, label="", option="Delete", action="deleterequest"}), page_info, -1)
		elseif viewlibrary.check_permission("deletemyrequest") then
			htmlviewfunctions.displayitem(cfe({type="form", value={request=req, cadir=cadir}, label="", option="Delete", action="deletemyrequest"}), page_info, -1)
		end
		%>
		</td>
		<td><%= html.html_escape(request.user) %></td>
		<td><%= html.html_escape(request.certtype) %></td>
		<td><%= html.html_escape(request.commonName) %></td>
		</tr>
	<% end %>
</tbody>
</table>
<% end %>
<% htmlviewfunctions.displaysectionend(header_level) %>

<% viewtype = cfe({type="hidden", value="stream"}) %>

<% local reverserevoked = {}
local approved = {}
local revoked = {}
if view.value.revoked and #view.value.revoked.value > 0 then
	for i,serial in ipairs(view.value.revoked.value) do
		reverserevoked[serial] = i
	end
	for i,cert in ipairs(view.value.approved.value) do
		if reverserevoked[cert.serial] then
			revoked[#revoked + 1] = cert
		else
			approved[#approved + 1] = cert
		end
	end
else
	approved = view.value.approved.value
end %>
	
<% htmlviewfunctions.displaysectionstart(cfe({label="Approved certificate requests"..label}), page_info, header_level) %>
<% if #approved == 0 then %>
	<p>No certificates approved</p>
<% else %>
<table id="approved" class="tablesorter">
<thead>
	<tr>
		<th>Action</th>
		<th>User</th>
		<th>Cert Type</th>
		<th>Common Name</th>
		<th>Serial Num</th>
		<th>End Date</th>
	</tr>
</thead>
<tbody>
	<% local crt = cfe({ type="hidden", value="" }) %>
	<% for i,cert in ipairs(approved) do %>
		<tr <% if cert.daysremaining < 14 then %>class='error'<% end %>>
		<td>
		<%
		crt.value = cert.cert
		if viewlibrary.check_permission("viewcert") then
			htmlviewfunctions.displayitem(cfe({type="link", value={cert=crt, cadir=cadir}, label="", option="View", action="viewcert"}), page_info, -1)
		end
		if viewlibrary.check_permission("getcert") then
			htmlviewfunctions.displayitem(cfe({type="link", value={cert=crt, viewtype=viewtype, cadir=cadir}, label="", option="Download", action="getcert"}), page_info, -1)
		end
		if viewlibrary.check_permission("renewcert") then
			htmlviewfunctions.displayitem(cfe({type="form", value={cert=crt, cadir=cadir}, label="", option="Renew", action="renewcert"}), page_info, -1)
		elseif viewlibrary.check_permission("requestrenewcert") then
			htmlviewfunctions.displayitem(cfe({type="form", value={cert=crt, cadir=cadir}, label="", option="Renew", action="requestrenewcert"}), page_info, -1)
		end
		if viewlibrary.check_permission("revoke") then
			htmlviewfunctions.displayitem(cfe({type="form", value={cert=crt, cadir=cadir}, label="", option="Revoke", action="revoke"}), page_info, -1)
		end
		if viewlibrary.check_permission("deletecert") then
			htmlviewfunctions.displayitem(cfe({type="form", value={cert=crt, cadir=cadir}, label="", option="Delete", action="deletecert"}), page_info, -1)
		end
		if viewlibrary.check_permission("managesubca") and cert.certtype == "ssl_ca_cert" then
			htmlviewfunctions.displayitem(cfe({type="form", value={cert=crt, cadir=cadir}, label="", option="Manage", action="managesubca"}), page_info, -1)
		end
		%>
		</td>
		<td><%= html.html_escape(cert.user) %></td>
		<td><%= html.html_escape(cert.certtype) %></td>
		<td><%= html.html_escape(cert.commonName) %></td>
		<td><%= html.html_escape(tostring(tonumber('0x'..cert.serial))) %></td>
		<td><%= html.html_escape(cert.enddate) %></td>
		</tr>
	<% end %>
<tbody>
</table>
<% end %>
<% htmlviewfunctions.displaysectionend(header_level) %>

<% htmlviewfunctions.displaysectionstart(cfe({label="Revoked certificates"..label}), page_info, header_level) %>
<% if #revoked == 0 then %>
	<p>No certificates revoked</p>
<% else %>
<table id="revoked" class="tablesorter">
<thead>
	<tr>
		<th>Action</th>
		<th>User</th>
		<th>Cert Type</th>
		<th>Common Name</th>
		<th>Serial Num</th>
	</tr>
</thead>
<tbody>
	<% local crt = cfe({ type="hidden", value="" }) %>
	<% for i,cert in ipairs(revoked) do %>
		<tr>
		<td>
		<%
		crt.value = cert.cert
		if viewlibrary.check_permission("viewcert") then
			htmlviewfunctions.displayitem(cfe({type="link", value={cert=crt, cadir=cadir}, label="", option="View", action="viewcert"}), page_info, -1)
		end
		--[[ if viewlibrary.check_permission("getcert") then
			htmlviewfunctions.displayitem(cfe({type="link", value={cert=crt, viewtype=viewtype, cadir=cadir}, label="", option="Download", action="getcert"}), page_info, -1)
		end --]]
		if viewlibrary.check_permission("deletecert") then
			htmlviewfunctions.displayitem(cfe({type="form", value={cert=crt, cadir=cadir}, label="", option="Delete", action="deletecert"}), page_info, -1)
		end
		%>
		</td>
		<td><%= html.html_escape(cert.user) %></td>
		<td><%= html.html_escape(cert.certtype) %></td>
		<td><%= html.html_escape(cert.commonName) %></td>
		<td><%= html.html_escape(tostring(tonumber('0x'..cert.serial))) %></td>
		</tr>
	<% end %>
</tbody>
</table>
<% end %>
<% htmlviewfunctions.displaysectionend(header_level) %>

<%
if viewlibrary.check_permission("getrevoked") then
	local cadir = cfe({type="hidden", value=view.value.cadir.value})
	htmlviewfunctions.displaysectionstart(cfe({label="Get revoked list (crl)"}), page_info, header_level)
	htmlviewfunctions.displayitem(cfe({type="link", value={crltype=cfe({type="hidden", value="PEM"}), viewtype=viewtype, cadir=cadir}, label="", option="Download PEM", action="getrevoked"}), page_info, -1)
	htmlviewfunctions.displayitem(cfe({type="link", value={crltype=cfe({type="hidden", value="DER"}), viewtype=viewtype, cadir=cadir}, label="", option="Download DER", action="getrevoked"}), page_info, -1)
	htmlviewfunctions.displaysectionend(header_level)
end
%>
