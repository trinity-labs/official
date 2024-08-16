<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>
<% json = require("json") %>
<% local sys = viewlibrary.dispatch_component("alpine-baselayout/health/system", nil, true) %>
<% local proc = viewlibrary.dispatch_component("alpine-baselayout/health/proc", nil, true) %>
<% local api = viewlibrary.dispatch_component("alpine-baselayout/health/api", nil, true) %>
<% local disk = viewlibrary.dispatch_component("alpine-baselayout/health/storage", nil, true) %>
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
	
-- FORMAT UPTIME	
	local up_time = math.floor(string.match(sys.value.uptime.value, "[%d]+"))
	local up_centuries = math.floor((up_time / (3600*24) / 365) / 100)
	local up_years = math.floor((up_time / (3600*24) / 365) % 100)
	local up_mounths = math.floor((((up_time / (3600 * 24)) % 365) % 365) / 30)
	local up_days = math.floor((((up_time / (3600 * 24)) % 365) % 365) % 30)
	local up_hours = string.format("%02d", math.floor((up_time % (3600 * 24)) / 3600))
	local up_minutes = string.format("%02d", math.floor(((up_time % (3600 * 24)) % 3600) / 60))
	local up_seconds = string.format("%02d", math.floor(((up_time % (3600 * 24)) % 3600) % 60))
	
-- CONVERT & DISPLAY UPTIME UP TO CENTURIES
	local uptime = up_centuries .. " Centuries " .. up_years .. " Years " .. up_mounths .. " Mounths " .. up_days .. " Days " .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"	
	if up_centuries == 1 then
		uptime = up_centuries .. " Century " .. up_years .. " Year " .. up_mounths .. " Mounths " .. up_days .. " Days " .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"
	elseif up_centuries == 0 then
		uptime =  up_years .. " Years " .. up_mounths .. " Mounths " .. up_days .. " Days " .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"
	end
	if up_years == 1 then
		uptime = up_years .. " Year " .. up_mounths .. " Mounths " .. up_days .. " Days " .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"
	elseif up_years == 0 then
		uptime = up_mounths .. " Mounths " .. up_days .. " Days " .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"
	end	
	if up_mounths == 1 then
		uptime = up_mounths .. " Mounth " .. up_days .. " Days " .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"
	elseif up_years == 0 and up_mounths == 0 then
		uptime = up_days .. " Days " .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"	
	end
	if up_days == 1 then
		uptime = up_days .. " Day " .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"
	elseif up_years == 0 and up_mounths == 0 and up_days == 0 then
		uptime = up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"	
	end
	
-- REPLACE O.E.M DEFAULT STRING
	function oem_parse(str)
		return (string.gsub(str, "To be filled by O.E.M." or "Not Specified", "Standard PC")) 
	end		
	function version_parse(str)
		return (string.gsub(str, "To be filled by O.E.M." or "Not Specified", "Unknow")) 
	end

-- GET INTERFACES
	local interfaces = {}
	for intf in pairs(netstats.value) do table.insert(interfaces, intf) end
	table.sort(interfaces)


-- FORMAT BYTES	
function bytesToSize(bytes)
	kilobyte = 1024;
	megabyte = kilobyte * 1024;
	gigabyte = megabyte * 1024;
	terabyte = gigabyte * 1024;
  if((bytes >= 0) and (bytes < kilobyte)) then
    return math.floor(bytes) .. " Bytes";
  elseif((bytes >= kilobyte) and (bytes < megabyte)) then
    return math.floor( bytes / kilobyte) .. ' KB';
  elseif((bytes >= megabyte) and (bytes < gigabyte)) then
    return math.floor( bytes / megabyte) .. ' MB';
  elseif((bytes >= gigabyte) and (bytes < terabyte)) then
    return string.format("%.2f", bytes / gigabyte) .. ' GB';
  elseif(bytes >= terabyte) then
    return string.format("%.2f", bytes / terabyte) .. ' TB';
  else
    return math.floor(bytes) .. ' B';
  end
end

-- FORMAT OCTETS
function blocksToSize(octets)
	kilooctet = 1024;
	megaoctet = kilooctet * 1024;
	gigaoctet = megaoctet * 1024;
	teraoctet = gigaoctet * 1024;
  if((octets >= 0) and (octets < kilooctet)) then
    return math.floor(octets) .. " Octets";
  elseif((octets >= kilooctet) and (octets < megaoctet)) then
    return math.floor( octets / kilooctet) .. ' Ko';
  elseif((octets >= megaoctet) and (octets < gigaoctet)) then
    return math.floor( octets / megaoctet) .. ' Mo';
  elseif((octets >= gigaoctet) and (octets < teraoctet)) then
    return string.format("%.2f", octets / gigaoctet) .. ' Go';
  elseif(octets >= teraoctet) then
    return string.format("%.2f", octets / teraoctet) .. ' To';
  else
    return math.floor(octets) .. ' o';
  end
end

-- GET DISKS & PARTITIONS
%>

<% local header_level = htmlviewfunctions.displaysectionstart(cfe({label="Dashboard"}), page_info) %>

<!-- Dashboard App Block - LINE 1 -->
<div class="dashboard-main main-block">

<!-- Dashboard Notification -->
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
					<span class="kernel-ver">Kernel @ <%= sys.value.kernel.value %> | ACF - <%= sys.value.luaver.value %></span>
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
	if(window.location.href.indexOf("welcome/read") > -1){
	let increment = <%= up_time or "unknow"%>;
	let delay = () => 
	{
	increment += 1;
	// CONVERT JS UPTIME
		var js_uptime = parseInt(increment);
		var js_centuries = Math.floor((js_uptime / (3600*24) / 365) / 100);
		var js_years = Math.floor((js_uptime / (3600*24) / 365) % 100);
		var js_mounths = Math.floor((((js_uptime / (3600 * 24)) % 365) % 365) / 30);
		var js_days = Math.floor((((js_uptime / (3600 * 24)) % 365) % 365) % 30)
		var js_hours = Math.floor(js_uptime % (3600*24) / 3600);
		var js_minutes = Math.floor(js_uptime % 3600 / 60);
		var js_seconds = Math.floor(js_uptime % 60);
	// FORMAT JS UPTIME UP TO CENTURIES
		var centuries_display = js_centuries > 0 ? js_centuries + (js_centuries <= 1 ? " Century " : " Centuries ") : "";
		var years_display = js_years > 0 ? js_years + (js_years <= 1 ? " Year " : " Years ") : "";
		var mounths_display = js_mounths > 0 ? js_mounths + (js_mounths <= 1 ? " Mounth " : " Mounths ") : "";
		var days_display = js_days > 0 ? js_days + (js_days <= 1 ? " Day " : " Days ") : "";
		var hours_display = js_hours < 10 ? "0" + js_hours + "h " : js_hours + "h ";
		var minutes_display = js_minutes < 10 ? "0" + js_minutes + "m " : js_minutes + "m ";
		var secondes_display = js_seconds < 10 ? "0" + js_seconds + "s" : js_seconds + "s";
	// RETURN JS FORMATED TIME
		return centuries_display + years_display + mounths_display + days_display + hours_display + minutes_display + secondes_display;	
	};
	// JS FORMATED TIME LIVE COUNT
		setInterval(() => document.getElementById("uptime").innerHTML = delay(), 1000);
	};
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
		</div>
	</div>
<!-- Dashboard App Block - LINE 1 -->
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

				</div>
	
<!-- Dashboard Main Block - DISK - BLOCK 2 -->	


</div>

<% htmlviewfunctions.displaysectionend(header_level) %>