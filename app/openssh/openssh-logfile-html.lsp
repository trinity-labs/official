<% local data, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>

<% htmlviewfunctions.displayinfo(data) %>

<% if viewlibrary and viewlibrary.dispatch_component then
	local clientdata = {}
	if data.value[1] then
		-- We have an array of logfile structures
		for i,l in ipairs(data.value) do
			clientdata = {}
			for n,v in pairs(l) do
				clientdata[n] = v
			end
			if clientdata.facility and clientdata.facility ~= "" then
				clientdata.facility = nil
				clientdata.filename = "/var/log/messages"
			end
			viewlibrary.dispatch_component("alpine-baselayout/logfiles/view", clientdata)
		end
	else
		for n,v in pairs(data.value) do
			clientdata[n] = v.value
		end
		if clientdata.facility and clientdata.facility ~= "" then
			clientdata.facility = nil
			clientdata.filename = "/var/log/messages"
		end
		if clientdata.filename and clientdata.filename ~= "" then
			viewlibrary.dispatch_component("alpine-baselayout/logfiles/view", clientdata)
		end
	end
end %>
