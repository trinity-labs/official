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
	   chkres = "<span id='alpine-version-link' class='version-link version-ok'><span class='version-check'>Up To Date <span class='version-number-uptodate'> ● </span> Alpine <a class='version-number-uptodate' href='https://www.alpinelinux.org/releases/#content' title='🟩 Up to Date' target='_blank'>" .. check_sysver .. "</a></span></span>"
	   kernres = ""
	else
		blockcolor = "<div class='data-block data-system system-update'>"
		chkres = "<span id='alpine-version-link' class='version-link version-update'><span class='version-check'>Update Needed <span class='version-number-update'> ● </span> Alpine <a class='version-number-update' href='https://www.alpinelinux.org/releases/#content' title='🟧 Update Needed' target='_blank'>" .. check_sysver .. "</a></span></span>"
		kernres = "<i class='fa-solid fa-exclamation icon-kernel-warn'></i>"
	end
	if major_sysver ~= major_distver then
		blockcolor = "<div class='data-block data-system system-upgrade'>"
		chkres = "<span id='alpine-version-link' class='version-link version-upgrade'><span class='version-check'>Upgrade Required <span class='version-number-upgrade'> ● </span> Alpine <a class='version-number-upgrade' href='https://www.alpinelinux.org/releases/#content' title='🟥 Upgrade Needed' target='_blank'>" .. check_sysver .. "</a></span></span>"
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
-- UPTIME LIKE GIT MONITORING
-- Function to calculate the last reboot date and time based on uptime
local function calculate_last_reboot(uptime_seconds)
    local current_time = os.time()
    local reboot_time = current_time - math.floor(uptime_seconds)
    local reboot_date_time = os.date("%Y-%m-%d %H:%M", reboot_time) -- Exclude seconds
    return reboot_date_time, reboot_time
end
-- Function to retrieve the current system uptime from the system
local function get_current_uptime()
    local uptime_output = sys.value.uptime.value
    local uptime_seconds = string.match(uptime_output, "[%d]+%.?[%d]*")
    return tonumber(uptime_seconds)
end
-- Function to read reboot data from the last_reboot file, handling the specific format
local function parse_last_reboot_file(filename)
    local reboots = {}
    local file = io.open(filename, "r")
    if not file then return reboots end
    for line in file:lines() do
        -- Look for the line that contains "Last Reboot from uptime:"
        local reboot_date = line:match("Last Reboot from uptime: (%d%d%d%d%-%d%d%-%d%d %d%d:%d%d)")
        if reboot_date then
            -- Extract year, month, day, hour, and minute from the matched date
            local year, month, day, hour, min = reboot_date:match("(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d)")

            -- Convert extracted values to a timestamp
            local reboot_time = os.time({
                year = tonumber(year),
                month = tonumber(month),
                day = tonumber(day),
                hour = tonumber(hour),
                min = tonumber(min),
                sec = 0 -- Assuming no seconds in the file
            })

            -- Add the reboot time to the list
            if reboot_time then
                table.insert(reboots, reboot_time)
            end
        end
    end
    file:close()
    return reboots
end
-- Function to analyze reboots from the last_reboot file and the current system uptime
local function analyze_reboots_and_uptime(last_reboot_filename)
    local last_reboot_file_reboots = parse_last_reboot_file(last_reboot_filename)
    local uptime_seconds = get_current_uptime()
    local last_reboot_from_uptime, last_reboot_time = calculate_last_reboot(uptime_seconds)
    local reboot_data = "Reboots from last_reboot file:\n" 
    -- Combine reboots from last_reboot file
    local combined_reboots = {}
    for _, reboot_time in ipairs(last_reboot_file_reboots) do
        table.insert(combined_reboots, reboot_time)
    end
    if #combined_reboots > 0 then
        for i, reboot_time in ipairs(combined_reboots) do
            local reboot_date_time = os.date("%Y-%m-%d %H:%M", reboot_time)
            reboot_data = reboot_data .. "Reboot " .. i .. ": " .. reboot_date_time .. "\n"
        end
    else
        reboot_data = reboot_data .. "No reboots found.\n"
    end
    reboot_data = reboot_data .. "\nLast Reboot from uptime: " .. last_reboot_from_uptime .. "\n"
    return reboot_data, last_reboot_time, combined_reboots
end
-- Function to check if the reboot data already exists in the file without seconds
local function check_if_reboot_exists(reboot_data, filename)
    local file = io.open(filename, "r")
    if not file then return false end

    local reboot_data_without_seconds = reboot_data:match("%Y%-m%-d %H:%M") -- Match format without seconds

    for line in file:lines() do
        local line_without_seconds = line:match("%Y%-m%-d %H:%M")
        if line_without_seconds == reboot_data_without_seconds then
            file:close()
            return true -- Reboot data already exists
        end
    end

    file:close()
    return false
end
-- Function to save the reboot data to a file only if it's different (ignoring seconds)
local function save_reboot_data(reboot_data, filename)
    -- Check if the reboot data already exists
    if not check_if_reboot_exists(reboot_data, filename) then
        local file = io.open(filename, "a")
        if file then
            file:write(reboot_data)
            file:close()
        end
    end
end
-- Function to generate the SVG calendar
local function generate_calendar(uptime_data)
    local box_size = 7
    local margin = 2 -- Spacing between boxes
    local cols = 52 -- 52 weeks
    local width = cols * (box_size + margin)
    local height = 7 * (box_size + margin) -- 7 days per week
    local svg = '<svg xmlns="http://www.w3.org/2000/svg" width="' .. width .. '" height="' .. height .. '">\n'
    -- Get the current day of the year
    local current_day_of_year = os.date("*t").yday
    local current_time = os.time()
    for i = 1, 365 do
        local x = math.floor((i-1) / 7) * (box_size + margin) -- X position (week)
        local y = ((i-1) % 7) * (box_size + margin) -- Y position (day of the week)
        -- Calculate the date corresponding to day i
        local time = os.time({year = os.date("*t").year, month = 1, day = 1}) + (i - 1) * 24 * 3600
        local date_str = os.date("%Y-%m-%d", time)
        local color
        if i > current_day_of_year then
            color = "#7676761f" -- future days
        else
            local reboots = uptime_data[i].reboots
            if reboots == 0 then
                color = "#3CDD4F" -- green for no reboots
            elseif reboots == 1 then
                color = "#E5FA00" -- yellow for 1 reboot
            elseif reboots > 1 then
                color = "#FFB700" -- orange for more than 1 reboot
            else
                color = "#7676761f" -- Default for unknown days
            end
        end
        svg = svg .. string.format(
            '<rect x="%d" y="%d" width="%d" height="%d" fill="%s" rx="1" stroke="#00000000" stroke-width="0.5" title="%s"/>\n',
            x, y, box_size, box_size, color, date_str
        )
    end
    svg = svg .. '</svg>'
    return svg
end
-- Function to save the SVG calendar to a file
local function save_svg_file(svg_content, filename)
    local file = io.open(filename, "w")
    file:write(svg_content)
    file:close()
end
-- Function to analyze uptimes and generate uptime data including reboots count
local function analyze_uptimes(reboots, last_reboot_time)
    local uptime_data = {}
    local current_time = os.time()
    local current_day_of_year = os.date("*t", current_time).yday
    -- Initialize the 365 days with unknown data and 0 reboots
    for i = 1, 365 do
        uptime_data[i] = {uptime = -1, reboots = 0}
    end
    -- Fill uptime data based on reboots and last reboot time
    if last_reboot_time then
        local days_since_last_reboot = math.floor((current_time - last_reboot_time) / (24 * 3600))
        for i = 0, days_since_last_reboot - 1 do
            local day_position = (current_day_of_year - i) % 365
            if day_position == 0 then day_position = 365 end
            uptime_data[day_position].uptime = 24
        end
    end
    for _, reboot_time in ipairs(reboots) do
        local day_of_year = os.date("*t", reboot_time).yday
        uptime_data[day_of_year].reboots = uptime_data[day_of_year].reboots + 1
    end
    return uptime_data
end
-- Start the process
local last_reboot_filename = "../../www/skins/dashboard/logs/reboot/last_reboot.txt"
local reboot_data, last_reboot_time, combined_reboots = analyze_reboots_and_uptime(last_reboot_filename)
save_reboot_data(reboot_data, last_reboot_filename)
-- Analyze uptimes and generate uptime data
local uptime_data = analyze_uptimes(combined_reboots, last_reboot_time)
-- Generate the SVG calendar
local svg_content = generate_calendar(uptime_data)
save_svg_file(svg_content, "../../www/skins/dashboard/img/reboot/uptime_calendar.svg")
local cache_time = os.date("%Y%m%d%H%M%S")
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
					<span class="kernel-ver">Kernel @ <%= sys.value.kernel.value .. kernres %> <span class='hdivider'>|</span> ACF - <%= sys.value.luaver.value %>
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
					print (" <span class='board-model corpo-hardware-text'>" .. sys.value.boardName.value .. "</span> ")
					print (version_parse(string.gsub(sys.value.boardVersion.value, "^", "")))
				-- AAEON EMB-H81B
				elseif string.match(sys.value.boardName.value, "EMB%-H81B") then
					print ("<span>" .. string.gsub(sys.value.boardVendor.value, "To be filled by O.E.M." or "Not Specified", "AAEON"))
					print (" <span class='board-model corpo-hardware-text'>" .. sys.value.boardName.value .. "</span> ")
					print (string.gsub(sys.value.boardVersion.value, "To be filled by O.E.M." or "Not Specified" or "Unknow", "Rev: 2.00") .. "</span>")
				-- AAEON EMB-Q87A
				elseif string.match(sys.value.boardName.value, "EMB%-Q87A") then
					print ("<span>" .. string.gsub(sys.value.boardVendor.value, "To be filled by O.E.M." or "Not Specified" or "Unknow", "AAEON"))
					print (" <span class='board-model corpo-hardware-text'>" .. sys.value.boardName.value .. "</span> ")
					print (string.gsub(sys.value.boardVersion.value, "To be filled by O.E.M." or "Not Specified" or "Unknow", "Rev: 2.00") .. "</span>")
				-- ELSE REWRITE ALL OTHERS
				else
					print ("<span>" .. oem_parse(sys.value.boardVendor.value))
					print (" pan class='board-model corpo-hardware-text'>" .. oem_parse(sys.value.boardName.value) .. "</span> ")
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
					<%= bytesToSize(tonumber(sys.value.memory.totalData)) %> Total <span class='hdivider'>|</span>
					<%= bytesToSize(tonumber(sys.value.memory.freeData)) %> Free <span class='hdivider'>|</span> 
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
										print (math.ceil(tonumber(api.value.boardTemp.value / 1000))  .. " °C  &nbsp; <span class='hdivider'>|</span> " .. "<span class='normal'>" .. math.floor(tonumber(api.value.cpuTemp.value / 1000)) .. " °C</span>")
										elseif ((tonumber(api.value.cpuTemp.value)) ~= nil) and ((tonumber(api.value.cpuTemp.value)) >= 50000) then
										print (math.ceil(tonumber(api.value.boardTemp.value / 1000))  .. " °C  &nbsp; <span class='hdivider'>|</span> " .. "<span class='medium'>" .. math.floor(tonumber(api.value.cpuTemp.value / 1000)) .. " °C</span>")
										elseif((tonumber(api.value.cpuTemp.value)) ~= nil) and ((tonumber(api.value.cpuTemp.value)) >= 75000) then
										print (math.ceil(tonumber(api.value.boardTemp.value / 1000))  .. " °C  &nbsp; <span class='hdivider'>|</span> " .. "<span class='hot'>" .. math.floor(tonumber(api.value.cpuTemp.value / 1000)) .. " °C</span>")
										else
										print ("<span class='nan'>N/A<span>")
										end
										%>			
										<script type="application/javascript" defer>
										// CONVERT TEMP TO FAHRENHEIT
										if (((<%= tonumber(api.value.cpuTemp.value) %>) < 50000) && (window.localStorage.getItem('toggle-degree') === 'fahrenheit')) {
												document.getElementById("cpuTemp").innerHTML = ((Math.ceil(((<%= tonumber(api.value.boardTemp.value) %>) / 1000) * 9 / 5) + 32) + " °F  &nbsp; <span class='hdivider'>|</span> <span class='normal'>" + (Math.floor(((<%= tonumber(api.value.cpuTemp.value) %>) / 1000) * 9 / 5) + 32)) + " °F</span>";
											} else if (((<%= tonumber(api.value.cpuTemp.value) %>) >= 50000) && (window.localStorage.getItem('toggle-degree') === 'fahrenheit')) {
												document.getElementById("cpuTemp").innerHTML = ((Math.ceil(((<%= tonumber(api.value.boardTemp.value) %>) / 1000) * 9 / 5) + 32) + " °F  &nbsp; <span class='hdivider'>|</span> <span class='medium'>" + (Math.floor(((<%= tonumber(api.value.cpuTemp.value) %>) / 1000) * 9 / 5) + 32)) + " °F</span>";
											} else if (((<%= tonumber(api.value.cpuTemp.value) %>) >= 75000) && (window.localStorage.getItem('toggle-degree') === 'fahrenheit')) {
												document.getElementById("cpuTemp").innerHTML = ((Math.ceil(((<%= tonumber(api.value.boardTemp.value) %>) / 1000) * 9 / 5) + 32) + " °F  &nbsp; <span class='hdivider'>|</span> <span class='hot'>" + (Math.floor(((<%= tonumber(api.value.cpuTemp.value) %>) / 1000) * 9 / 5) + 32)) + " °F</span>";
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
<p class="dashboard-title uptime-heatmap-title"><i class="fa-solid fa-square"></i> Uptime Heatmap</p>
<p class="months-list">
    <span class="month january">January</span>
    <span class="month february">February</span>
    <span class="month march">March</span>
    <span class="month april">April</span>
    <span class="month may">May</span>
    <span class="month june">June</span>
    <span class="month july">July</span>
    <span class="month august">August</span>
    <span class="month september">September</span>
    <span class="month october">October</span>
    <span class="month november">November</span>
    <span class="month december">December</span>
</p>
<img id="uptime-calendar" src="/skins/dashboard/img/reboot/uptime_calendar.svg?<%= cache_time %>" width="100%" height="auto" xmlns="http://www.w3.org/2000/svg" />
<div id="tooltip" style="position: absolute; display: none; background-color: #fff; border: 1px solid #000; padding: 5px;"></div>
<div class="chart-bar chart-legend chart-heatmap">
	<span><i class="fa-solid fa-square" id="legend-uptime-0reboot"></i><span class="legend-title">No Reboot</span></span>
	<span><i class="fa-solid fa-square" id="legend-uptime-1reboot"></i><span class="legend-title">Reboot 1 Time</span></span>
	<span><i class="fa-solid fa-square" id="legend-uptime-2reboot"></i><span class="legend-title">More 1 Reboot</span></span>
</div>
<script>
document.addEventListener('DOMContentLoaded', function() {
    var currentMonth = new Date().getMonth();
    var months = document.querySelectorAll('.months-list .month');
    months[currentMonth].classList.add('active');
	if (window.matchMedia("(max-width: 1080px)").matches) {
        const months = document.querySelectorAll('.month');
        months.forEach(function(month) {
            month.textContent = month.textContent.slice(0, 3);
        });
    }
});
</script>
<!-- Dashboard App Block - LINE 2 -->
<p class="dashboard-title uptime-heatmap-title"><i class="fa-solid fa-square"></i> System Health Charts</p>
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
<div class="dashboard-main main-block data-disk">
<!-- Dashboard Main Block - SYSTEM - BLOCK 1 -->
<div class="disk-list">
<p class="dashboard-title"><i class="fa-solid fa-square"></i> Disk List</p>
<%
local used_colors = {}
local function get_random_number(min, max)
    return math.floor(math.random() * (max - min + 1)) + min
end
local function table_size(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end
local function is_color_too_close(hue, min_distance)
    for used_hue, _ in pairs(used_colors) do
        if math.abs(used_hue - hue) < min_distance then
            return true
        end
    end
    return false
end
local function get_random_color()
    local min_hue_distance = 30
    if table_size(used_colors) >= 50 then
        used_colors = {}
    end
    local hue
    local color
    local replaced = false
    repeat
        hue = get_random_number(0, 360)
    until not is_color_too_close(hue, min_hue_distance)
    color = string.format("hsl(%d, %d%%, %d%%)", hue, get_random_number(40, 60), get_random_number(45, 65))
    bgcolor = color:gsub("(%d+)%%", function(num) return tostring(tonumber(num) + 10) .. "%" end, 2)
    used_colors[hue] = true
    return color, bgcolor
end
displaydisk = function(disk, name)
local used_color = get_random_color()
io.write('<div id="disk-listing">\n')
io.write('<div class="chart-bar chart-storage">\n')
    if tonumber(disk.used) >= 0 and tonumber(disk.used) <= 25 then
        io.write('<div id="capacity-used" class="capacity-used" style="width:25%; margin:0; border:none; background-color:'.. used_color ..'">\n')
        io.write('<center><b>'.. bytesToSize(tonumber(disk.use) * 1024) ..'</b></center></div>\n')
	elseif tonumber(disk.used) > 25 then
        io.write('<div id="capacity-used" class="capacity-used" style="width:'..html.html_escape(disk.used)..'%;margin:0; border:none; background-color:'..used_color..'; transition:width 0.5s ease-in-out, background-color 0.5s ease-in-out;">\n')
        io.write('<center><b>'.. bytesToSize(tonumber(disk.use) * 1024) ..'</b></center></div>\n')
    end
if tonumber(disk.used) < 100 then
    io.write('<div id="capacity-free" class="capacity-free" style="width:'..(100 - tonumber(disk.used))..'%; background-color:'..bgcolor..'">\n')
    io.write('</div>\n')
end
io.write('</div>\n')
io.write('<h2 id="disk-title"><i class="fa-solid fa-square" style="color:'..used_color..'"></i>  '.. html.html_escape(disk.model) ..'</h2>\n')
io.write('<div id="legend-title">\n')
io.write('<i class="bi bi-device-ssd-fill icon-disk-listing"></i>\n')
io.write('<div id="legend-object">\n')
if disk.model ~= nil then
    io.write('<p class="dashboard-infos"><span class="data-title">Brand</span>'.. string.match(disk.model, "%S+") ..'</p>')
else
    io.write('<p class="dashboard-infos"><span class="data-title">Brand</span><span class="brand-name"> Unknow</span></p>')
end
io.write('<p class="dashboard-infos"><span class="data-title">Mount</span><span class="mount-point">'.. disk.mount_point:gsub("^(.{30}).*", "%1") ..'</span></p>')
io.write('<p class="dashboard-infos"><span class="data-title">Size</span><span class="disk-size">'.. string.gsub((math.floor(tonumber((bytesToSize(disk.size * 1024)):match("%d+%.?%d*"))) .. " " .. (bytesToSize(disk.size * 1024)):match("%a+")), "%D+%S%A+", " ") ..'</span></p>\n')
io.write('</div>\n')
io.write('<div id="legend-object">\n')
io.write('<p class="dashboard-infos"><span class="data-title">Name</span><span class="linux-name">' .. html.html_escape(name) .. '</span></p>\n')
io.write('<p class="dashboard-infos"><span class="data-title">Used</span>'.. html.html_escape(disk.used) .. "%" .. '</p>\n')
io.write('<p class="dashboard-infos"><span class="data-title">Available</span>'.. bytesToSize(tonumber(disk.available) * 1024) .. '</p>\n')
io.write('</div>\n')
io.write('</div>\n')
io.write('</div>\n')
end
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