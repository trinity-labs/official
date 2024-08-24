<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>
<% json = require("json") %>
<% local sys = viewlibrary.dispatch_component("alpine-baselayout/health/system", nil, true) %>
<% local proc = viewlibrary.dispatch_component("alpine-baselayout/health/proc", nil, true) %>
<% local api = viewlibrary.dispatch_component("alpine-baselayout/health/api", nil, true) %>
<% local volume = viewlibrary.dispatch_component("alpine-baselayout/health/storage", nil, true) %>
<% local net = viewlibrary.dispatch_component("alpine-baselayout/health/network", nil, true) %>
<% local netstats = viewlibrary.dispatch_component("alpine-baselayout/health/networkstats", nil, true) %>
<% 
-- PROTECT HOSTNAME WITH SESSION
	local hostname = ""
	if session.userinfo and session.userinfo.userid and viewlibrary and viewlibrary.dispatch_component then
	local result = viewlibrary.dispatch_component("alpine-baselayout/hostname/read", nil, true)
		if result and result.value then
			hostname = result.value
		end
	end
-- CHECK SYS RELEASE VERSION
	local check_sysver = string.match(sys.value.version.value, "%d+.%d+.%d+") -- Check Local System Version
	local major_sysver = string.match(check_sysver, "%d+") -- Parse Major for Upgrade
	local minor_sysver = string.gsub(string.match(check_sysver, "%p%d+"), "%D", "") -- Parse Minor for Update
	local patch_sysver = string.gsub(string.match(check_sysver, ".[^.]*$"), "%D", "") -- Parse Patch for Update	
-- CHECK DIST RELEASE VERSION
	local check_distver = (sys.value.alpinever.value) -- Get All Versions from Alpine Linux Official Website
	local actual_distver = string.match(string.match(check_distver, "version\":\"%d+.%d+.%d+"), "%d+.%d+.%d+") -- Get Last Version
	local major_distver = string.match(actual_distver, "%d+") -- Parse Major for Upgrade
	local minor_distver = string.gsub(string.match(actual_distver, "%p%d+"), "%D", "") -- Parse Minor for Update
	local patch_distver = string.gsub(string.match(actual_distver, ".[^.]*$"), "%D", "") -- Parse Patch for Fix
	if major_sysver == major_distver and minor_sysver == minor_distver and patch_sysver == patch_distver then
	   blockcolor = "<div class='data-block data-system system-uptodate'>"
	   chkres = "<span id='alpine-version-link' class='version-link version-ok'><span class='version-check'>Up To Date | Alpine <a class='version-number-uptodate' href='https://www.alpinelinux.org/releases/#content' title='🟩 Up to Date' target='_blank'>" .. check_sysver .. "</a></span></span>"
	else
		blockcolor = "<div class='data-block data-system system-update'>"
		chkres = "<span id='alpine-version-link' class='version-link version-update'><span class='version-check'>Update Needed | Alpine <a class='version-number-update' href='https://www.alpinelinux.org/releases/#content' title='🟧 Update Needed' target='_blank'>" .. check_sysver .. "</a></span></span>"
		kernres = "<i class='fa-solid fa-exclamation icon-kernel-warn'></i>"
	end
	if major_sysver ~= major_distver then
		blockcolor = "<div class='data-block data-system system-upgrade'>"
		chkres = "<span id='alpine-version-link' class='version-link version-upgrade'><span class='version-check'>Upgrade Required | Alpine <a class='version-number-upgrade' href='https://www.alpinelinux.org/releases/#content' title='🟥 Upgrade Needed' target='_blank'>" .. check_sysver .. "</a></span></span>"
		kernres = "<i class='fa-solid fa-xmark icon-kernel-err'></i>"
	end	
-- GET DIST VERSION CHANGES
	local get_verchanges = string.match(sys.value.alpineposts.value, "[%p?%d?.%d?.%d?]+%p?".. actual_distver .."[%p?%d?.%d?.%d?]+")
	
-- HELPER FORMAT TIME UNIT
	local function formatTime(value, singular, plural)
		return value > 0 and value .. " " .. (value == 1 and singular or plural) .. " " or ""
	end
-- FORMAT TIME
	local up_time = math.floor(string.match(sys.value.uptime.value, "[%d]+"))
	local up_centuries = math.floor(up_time / (3600 * 24 * 365 * 100))
	local up_years = math.floor((up_time / (3600 * 24 * 365)) % 100)
	local up_months = math.floor(((up_time / (3600 * 24)) % 365) / 30)
	local up_days = math.floor(((up_time / (3600 * 24)) % 365) % 30)
	local up_hours = string.format("%02d", math.floor((up_time % (3600 * 24)) / 3600))
	local up_minutes = string.format("%02d", math.floor((up_time % 3600) / 60))
	local up_seconds = string.format("%02d", up_time % 60)
	local uptime = ""
	uptime = uptime .. formatTime(up_centuries, "Century", "Centuries")
	uptime = uptime .. formatTime(up_years, "Year", "Years")
	uptime = uptime .. formatTime(up_months, "Mounth", "Mounths")
	uptime = uptime .. formatTime(up_days, "Day", "Days")
	uptime = uptime .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"
	uptime = uptime:match("^%s*(.-)%s*$")	
-- REPLACE O.E.M DEFAULT STRING
	local function oem_parse(str)
		return (string.gsub(str, "To be filled by O.E.M." or "Not Specified", "Standard PC")) 
	end		
	local function version_parse(str)
		return (string.gsub(str, "To be filled by O.E.M." or "Not Specified", "Unknow")) 
	end
-- GET INTERFACES
	local interfaces = {}
		for intf in pairs(netstats.value) do table.insert(interfaces, intf) end
	table.sort(interfaces)
-- FORMAT BYTES	
	local function bytesToSize(bytes)
		local units = {"Bytes", "KiB", "MiB", "GiB", "TiB"}
		local thresholds = {1024, 1024^2, 1024^3, 1024^4}   
		for i = #thresholds, 1, -1 do
			if bytes >= thresholds[i] then
				return string.format("%.2f %s", bytes / thresholds[i], units[i + 1])
			end
		end
		return string.format("%d %s", bytes, units[1])
	end
-- FORMAT OCTETS
	local function blocksToSize(octets)
		local units = {"Octets", "Kio", "Mio", "Gio", "Tio"}
		local thresholds = {1024, 1024^2, 1024^3, 1024^4}   
		for i = #thresholds, 1, -1 do
			if octets >= thresholds[i] then
				return string.format("%.2f %s", octets / thresholds[i], units[i + 1])
			end
		end
		return string.format("%d %s", octets, units[1])
	end
-- GET DISKS & PARTITIONS
%>
<% local header_level = htmlviewfunctions.displaysectionstart(cfe({label="Dashboard"}), page_info) %>
<!-- Dashboard App Block - LINE 1 -->
<div class="dashboard-main main-block">
	<!-- Dashboard Version Block - BLOCK 1 -->
	<div class="dashboard-system dashboard-block">
		<%= blockcolor %>
		<h4 class="dashboard-block-title dashboard-title-system">System</h4>
			<span class="icon-os"></span> 
				<p class="dashboard-infos dash-info-version">
					<%= chkres %>
					<span class="check-version">
						<a class="version-link version-external-link" href="https://www.alpinelinux.org/posts/Alpine<%= get_verchanges %>released.html#content" title="🔗 https://www.alpinelinux.org/posts/Alpine<%= get_verchanges %>released.html#content" target="_blank">Last Release : <%= actual_distver %></a><br>
					</span>
					<span class="kernel-ver">Kernel @ <%= sys.value.kernel.value %> | ACF - <%= sys.value.luaver.value %>
					</span>
				</p>
	</div>
<!-- Dashboard Hardware Block - 2 -->
	<div class="data-block data-hardware">
		<h4 class="dashboard-block-title dashboard-title-hardware">Hardware</h4>
			<span class="icon-cpu">
				<% if string.find((proc.value.model.value), "Intel") then
					print ("<canvas class='icon-canvas-dash icon-intel'>''</canvas>")
				elseif string.find((proc.value.model.value), "AMD") then
					print ("<canvas class='icon-canvas-dash icon-amd'>''</canvas>")
				else
					print ("<canvas class='icon-canvas-dash icon-arm'>''</canvas>")
				end %>
			</span>
			<p class="dashboard-infos">
				<span class="data-title">Board</span>
				<%
				-- EXEMPLE TO PARSE KNOW MOBO MODELS OR YOUR OWN ONE
				-- REWRITE ASUS BRAND NAME
				if string.match(sys.value.boardVendor.value, "ASUSTeK COMPUTER INC.") then
					print ("<span>" .. string.gsub(sys.value.boardVendor.value, "ASUSTeK COMPUTER INC.", "ASUS"))
					print (" | <span class='board-model corpo-hardware-text'>" .. sys.value.boardName.value .. "</span> | ")
					print (version_parse(string.gsub(sys.value.boardVersion.value, "^", "")))
				-- AAEON EMB-H81B
				elseif string.match(sys.value.boardName.value, "EMB%-H81B") then
					print ("<span>" .. string.gsub(sys.value.boardVendor.value, "To be filled by O.E.M." or "Not Specified", "AAEON"))
					print (" | <span class='board-model corpo-hardware-text'>" .. sys.value.boardName.value .. "</span> | ")
					print (string.gsub(sys.value.boardVersion.value, "To be filled by O.E.M." or "Not Specified" or "Unknow", "Rev: 2.00") .. "</span>")
				-- AAEON EMB-Q87A
				elseif string.match(sys.value.boardName.value, "EMB%-Q87A") then
					print ("<span>" .. string.gsub(sys.value.boardVendor.value, "To be filled by O.E.M." or "Not Specified" or "Unknow", "AAEON"))
					print (" | <span class='board-model corpo-hardware-text'>" .. sys.value.boardName.value .. "</span> | ")
					print (string.gsub(sys.value.boardVersion.value, "To be filled by O.E.M." or "Not Specified" or "Unknow", "Rev: 2.00") .. "</span>")
				-- ELSE REWRITE ALL OTHERS
				else
					print ("<span>" .. oem_parse(sys.value.boardVendor.value))
					print (" | <span class='board-model corpo-hardware-text'>" .. oem_parse(sys.value.boardName.value) .. "</span> | ")
					print (version_parse(string.gsub(sys.value.boardVersion.value, "^", "Rev : ")))
				end
				%>
			</p>
			<p class="dashboard-infos dash-info-cpu" style="cursor: pointer;" onclick="window.open('/cgi-bin/acf/alpine-baselayout/health/proc', '_blank')" >
				<span class="data-title">CPU</span><%= string.sub((proc.value.model.value), 14) %>
			</p>
			<p class="dashboard-infos dash-info-memory" style="cursor: pointer;" onclick="window.open('/cgi-bin/acf/alpine-baselayout/health/proc', '_blank')" >
				<span class="data-title">Memory</span>
				<span>
					<%= bytesToSize(tonumber(sys.value.memory.totalData)) %> Total |
					<%= bytesToSize(tonumber(sys.value.memory.freeData)) %> Free | 
					<span class='mem-used corpo-hardware-text'>
					<%= bytesToSize(tonumber(sys.value.memory.usedData)) %> Used </span>
				</span>
			</p>	
	</div>
<!-- Dashboard Monitoring Block - 3 -->
		<div class="data-block data-monitoring">
			<h4 class="dashboard-block-title dashboard-title-system-uptime">Monitoring</h4>
				<span class="icon-trinity"></span>
					<p class="dashboard-infos">
						<span class="data-title">Uptime</span>
							<span id="uptime" class="uptime">
								<%= uptime %><br>
								<script type="application/javascript">
									// IMPORT UPTIME FOR JS LIVE TIMER
									if (location.href.includes("welcome/read")) {
										let increment = "<%= up_time or 'unknown' %>";
										const formatTime = () => {
											increment++;
											const js_uptime = parseInt(increment, 10);
											const centuries = Math.floor(js_uptime / 3.15576e+9); // 100 years in seconds
											const years = Math.floor((js_uptime % 3.15576e+9) / 3.15576e+7); // 1 year in seconds
											const months = Math.floor((js_uptime % 3.15576e+7) / 2.62974e+6); // 1 month in seconds
											const days = Math.floor((js_uptime % 2.62974e+6) / 86400); // 1 day in seconds
											const hours = String(Math.floor((js_uptime % 86400) / 3600)).padStart(2, '0');
											const minutes = String(Math.floor((js_uptime % 3600) / 60)).padStart(2, '0');
											const seconds = String(js_uptime % 60).padStart(2, '0');
											return `${centuries ? centuries + (centuries === 1 ? " Century " : " Centuries ") : ""}` +
												   `${years ? years + (years === 1 ? " Year " : " Years ") : ""}` +
												   `${months ? months + (months === 1 ? " Month " : " Months ") : ""}` +
												   `${days ? days + (days === 1 ? " Day " : " Days ") : ""}` +
												   `${hours}h ${minutes}m ${seconds}s`;
										};
										setInterval(() => document.getElementById("uptime").textContent = formatTime(), 1000);
									}
								</script>
						</span>
					</p>
					<p class="dashboard-infos">
						<span class="data-title">System Temp</span>
							<a href='javascript:void(0);' id='toggle-degree' title='Celsius to Fahrenheit' onclick='toggleDegree()'>
								<span id="cpuTemp" class="dash-monitoring-temp">			
										<%
										if ((tonumber(api.value.cpuTemp.value)) ~= nil) and ((tonumber(api.value.cpuTemp.value)) < 50000) then
										print (math.ceil(tonumber(api.value.boardTemp.value / 1000))  .. " °C  &nbsp; | " .. "<span class='normal'>" .. math.floor(tonumber(api.value.cpuTemp.value / 1000)) .. " °C</span>")
										elseif ((tonumber(api.value.cpuTemp.value)) ~= nil) and ((tonumber(api.value.cpuTemp.value)) >= 50000) then
										print (math.ceil(tonumber(api.value.boardTemp.value / 1000))  .. " °C  &nbsp; | " .. "<span class='medium'>" .. math.floor(tonumber(api.value.cpuTemp.value / 1000)) .. " °C</span>")
										elseif((tonumber(api.value.cpuTemp.value)) ~= nil) and ((tonumber(api.value.cpuTemp.value)) >= 75000) then
										print (math.ceil(tonumber(api.value.boardTemp.value / 1000))  .. " °C  &nbsp; | " .. "<span class='hot'>" .. math.floor(tonumber(api.value.cpuTemp.value / 1000)) .. " °C</span>")
										else
										print ("<span class='nan'>N/A<span>")
										end
										%>			
										<script type="application/javascript" defer>
										// CONVERT TEMP TO FAHRENHEIT
										if (((<%= tonumber(api.value.cpuTemp.value) %>) < 50000) && (window.localStorage.getItem('toggle-degree') === 'fahrenheit')) {
												document.getElementById("cpuTemp").innerHTML = ((Math.ceil(((<%= tonumber(api.value.boardTemp.value) %>) / 1000) * 9 / 5) + 32) + " °F  &nbsp; | <span class='normal'>" + (Math.floor(((<%= tonumber(api.value.cpuTemp.value) %>) / 1000) * 9 / 5) + 32)) + " °F</span>";
											} else if (((<%= tonumber(api.value.cpuTemp.value) %>) >= 50000) && (window.localStorage.getItem('toggle-degree') === 'fahrenheit')) {
												document.getElementById("cpuTemp").innerHTML = ((Math.ceil(((<%= tonumber(api.value.boardTemp.value) %>) / 1000) * 9 / 5) + 32) + " °F  &nbsp; | <span class='medium'>" + (Math.floor(((<%= tonumber(api.value.cpuTemp.value) %>) / 1000) * 9 / 5) + 32)) + " °F</span>";
											} else if (((<%= tonumber(api.value.cpuTemp.value) %>) >= 75000) && (window.localStorage.getItem('toggle-degree') === 'fahrenheit')) {
												document.getElementById("cpuTemp").innerHTML = ((Math.ceil(((<%= tonumber(api.value.boardTemp.value) %>) / 1000) * 9 / 5) + 32) + " °F  &nbsp; | <span class='hot'>" + (Math.floor(((<%= tonumber(api.value.cpuTemp.value) %>) / 1000) * 9 / 5) + 32)) + " °F</span>";
										}
										</script>			
								</span>
							</a>
						</p>
						<p class="dashboard-infos">
							<span class="data-title">IP</span>
							<span class="value-title value-net-local"><%= net.value.wanIP.value %>  &nbsp; via &nbsp; <%= netstats.value.br0.ipaddr %></span>
						</p>
			</div>
	</div>
<!-- END Dashboard App Block - LINE 1 -->
</div>
<!-- Dashboard App Block - LINE 2 -->
<div class="dashboard-main main-block">
<!-- Dashboard CPU Block - 1 -->
	<div class="data-block data-cpu">
		<h4 class="dashboard-block-title dashboard-title-cpu-stats">CPU Temp</h4>
		<!-- Dashboard Main Block - NETWORK CHART.JS -->	
		<canvas id="chartCpuTemp" class="data-chart block-chart"></canvas>
	</div>		
<!-- Dashboard Memory Block - 2 -->		
	<div class="data-block data-memory">
		<h4 class="dashboard-block-title dashboard-title-memory-stats">Memory Usage</h4>
		<!-- Dashboard Main Block - NETWORK CHART.JS -->	
		<canvas id="chartMemUsed" class="data-chart block-chart"></canvas>
	</div>
<!-- Dashboard App Block - LINE 2 -->
</div>
<!-- Dashboard App Block - LINE 3 -->
<div class="dashboard-main main-block">
<!-- Dashboard Main Block - SYSTEM - BLOCK 1 -->
<div class="disk-list">
<p class="dashboard-title"><i class="fa-solid fa-square"></i> Disk List</p>
<%
-- Random Colors in Range Function without Duplicate Colors 
local used_colors = {}
local function get_random_number(min, max)
    return math.floor(math.random() * (max - min + 1)) + min
end
local function table_size(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end
local function get_random_color()
    local hue_ranges = {
        {min = 100, max = 160},  -- Green
        {min = 50, max = 80},    -- Yellow
        {min = 210, max = 260}   -- Blue
    }
    if table_size(used_colors) >= 25 then
        used_colors = {}
    end
    local color
    repeat
        local range = hue_ranges[get_random_number(1, #hue_ranges)]
        local h = get_random_number(range.min, range.max)
        color = string.format("hsl(%d, 60%%, 60%%)", h)
    until not used_colors[color]
    used_colors[color] = true
    return color
end
%>
<% displaydisk = function(disk, name)
    local used_color = get_random_color()
	io.write('<div id="disk-listing">\n')
    io.write('<table id="legend-title">\n')
    io.write("    <tr>\n")
    io.write('        <td id="legend-object" width="100px"><b><span class="linux-name"><i class="fa-solid fa-database icon-disk">\n')
	io.write('</i> Disk '..html.html_escape(name)..'</span> | <span class="brand-name" style="color:'..used_color..'">'..html.html_escape(disk.model)..'</span>\n')
	io.write('<span class="disk-right-inf"><span class="mount-point"><i class="fa-solid fa-folder-closed icon-disk icon-disk-right"></i> '..html.html_escape(disk.mount_point)..'</span>')
    io.write('<i class="fa-solid fa-chart-simple icon-disk icon-disk-right"></i> Used <span class="disk-used" style="color:'..used_color..'">'..html.html_escape(disk.used) .. "%" .. '</span></span></b></td>\n')
	io.write("    </tr>\n")
    io.write("</table>\n")
    io.write('<table class="chart-bar chart-storage">\n')
    io.write("    <tr>\n")
    io.write("        <td>0%</td>\n")
    if tonumber(disk.used) >= 0 and tonumber(disk.used) <= 5 then
        io.write('        <td id="capacity-used" class="capacity-used" width="5%" style="margin:0; border:none; background-color:'..used_color..'">\n')
        io.write('<center><b>'.. bytesToSize(tonumber(disk.use) * 1024) ..'</b></center></td>\n')
	elseif tonumber(disk.used) > 10 then
        io.write('        <td id="capacity-used" class="capacity-used" width="'..html.html_escape(disk.used)..'%" style="margin:0; border:none; background-color:'..used_color..'; transition: width 0.5s ease-in-out;">\n')
        io.write('<center><b>'.. bytesToSize(tonumber(disk.use) * 1024) ..'</b></center></td>\n')
    end
    if tonumber(disk.used) < 100 then
        io.write('        <td id="capacity-free" class="capacity-free" width="'..(100-tonumber(disk.used))..'%" style="margin:0; border:none;">\n')
        io.write('<center><b>'.. bytesToSize(tonumber(disk.available) * 1024) ..' <span class="free-chart-disk">(Free)</span></b></center></td>\n')
    end
	io.write('        <td>100%</td>\n')
	io.write("    </tr>\n")
	io.write("</table>\n")
	io.write("</div>\n")
end
%>
<%
if (volume.value.hd) then
    for name,hd in pairs(volume.value.hd.value) do
        displaydisk(hd, name)
    end
else
    io.write('<p class="error error-txt">No Hard Drive Mounted</p>\n')
end
%>
</div>	
<!-- Dashboard Main Block - DISK - BLOCK 2 -->	
</div>
<% htmlviewfunctions.displaysectionend(header_level) %>