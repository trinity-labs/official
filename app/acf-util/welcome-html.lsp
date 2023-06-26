<% local view, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>
<% json = require("json") %>

<% local sys = viewlibrary.dispatch_component("alpine-baselayout/health/system", nil, true) %>
<% local proc = viewlibrary.dispatch_component("alpine-baselayout/health/proc", nil, true) %>
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
	local check_sysver = string.match(sys.value.version.value, "%d+.%d+.%d+")
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
		chkres = "<a id='alpine-version-link' class='version-link version-ok' href='https://www.alpinelinux.org/releases/' title='🟩 Up to Date' target='_blank'><span class='version-check-ok'>Alpine Linux | <span class='version-letter'>" .. check_sysver .. "</span></span></a> up to date "
	else
		chkres = "<a id='alpine-version-link' class='version-link version-update' href='https://www.alpinelinux.org/releases/' title='🟧 Update Needed' target='_blank'><span class='version-check-update'>Alpine Linux | <span class='version-letter'>" .. check_sysver .. "</span></span></a>update needed "
	end
	if major_sysver ~= major_distver then
		chkres = "<a id='alpine-version-link' class='version-link version-upgrade' href='https://www.alpinelinux.org/releases/' title='🟥 Upgrade Needed' target='_blank'><span class='version-check-upgrade'>Alpine Linux | <span class='version-letter'>" .. check_sysver .. "</span></span></a>upgrade required "
	end
	
-- GET DIST VERSION CHANGES
	local check_verchanges = string.gsub(string.match(string.match(sys.value.alpineposts.value, "(href=\"Alpine-.+("..actual_distver.."))(.+\")"), "\".+\""), "\"", "")
	
-- FORMAT UPTIME	
	local up_time = math.floor(string.match(sys.value.uptime.value, "[%d]+"))
	local up_years = math.floor(up_time / (3600 * 24) / 365)
	local up_mounths = math.floor((((up_time / (3600 * 24)) % 365) % 365) / 30)
	local up_days = math.floor((((up_time / (3600 * 24)) % 365) % 365) % 30)
	local up_hours = string.format("%02d", math.floor((up_time % (3600 * 24)) / 3600))
	local up_minutes = string.format("%02d", math.floor(((up_time % (3600 * 24)) % 3600) / 60))
	local up_seconds = string.format("%02d", math.floor(((up_time % (3600 * 24)) % 3600) % 60))
	
-- REPLACE O.E.M DEFAULT STRING
	function oem_parse(str)
		return (string.gsub(str, "To be filled by O.E.M." or "Not Specified", "Standard PC")) 
	end		
	function version_parse(str)
		return (string.gsub(str, "To be filled by O.E.M." or "Not Specified", "Unknow")) 
	end
	
		-- Table of colors
	local rgb = {
		{"rgb(0,192,128)","rgb(64,255,192)"},
		{"rgb(128,0,192)","rgb(192,64,255)"},
		{"rgb(0,128,192)","rgb(64,192,255)"},
		{"rgb(192,0,128)","rgb(255,64,192)"},
		{"rgb(128,192,0)","rgb(192,255,64)"},
		{"rgb(192,128,0)","rgb(255,192,64)"},
		{"rgb(0,0,0)","rgb(128,128,128)"},
		{"rgb(128,0,0)","rgb(192,64,64)"},
		{"rgb(0,128,0)","rgb(64,192,64)"},
		{"rgb(0,0,128)","rgb(64,64,192)"},
		{"rgb(128,128,0)","rgb(192,192,64)"},
		{"rgb(0,128,128)","rgb(64,192,192)"},
		{"rgb(128,0,128)","rgb(192,64,192)"},
		{"rgb(192,192,192)","rgb(255,255,255)"},
		{"rgb(192,128,128)","rgb(255,192,192)"},
		{"rgb(128,192,128)","rgb(192,255,192)"},
		{"rgb(128,128,192)","rgb(192,192,255)"},
		{"rgb(192,128,192)","rgb(255,192,255)"},
		{"rgb(128,192,192)","rgb(192,255,255)"},
		{"rgb(192,192,128)","rgb(255,255,192)"},
	}

	local interfaces = {}
	for intf in pairs(netstats.value) do table.insert(interfaces, intf) end
	table.sort(interfaces)
	
		
function bytesToSize(bytes)
  kilobyte = 1000;
  megabyte = kilobyte * 1000;
  gigabyte = megabyte * 1000;
  terabyte = gigabyte * 1000;

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

function blocksToSize(bytes)
  kilobyte = 1000;
  megabyte = kilobyte * 1000;
  gigabyte = megabyte * 1000;
  terabyte = gigabyte * 1000;

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
	
%>

<% local header_level = htmlviewfunctions.displaysectionstart(cfe({label="Dashboard"}), page_info) %>

<!-- Dashboard App Block - LINE 1 -->
<div class="dashboard-main main-block">
<!-- Dashboard Version Block - BLOCK 1 -->
	<div class="dashboard-system dashboard-block">
		<div class="data-block data-system">
			<h4 class="dashboard-block-title dashboard-title-system">System</h4>
				<p class="dashboard-infos dash-info-version">
					<span class="data-title">OS : </span>
					<%= chkres %>
					<span class="check-version">
					 &nbsp; - &nbsp;
					 <a class="version-link version-external-link" href="https://www.alpinelinux.org/posts/<%= check_verchanges %>" title="🔗 https://www.alpinelinux.org/posts/<%= check_verchanges %>" target="_blank">Last Release : <%= actual_distver %></a><br>
					 </span>
					<span class="data-title">ACF Version : </span><%= sys.value.luaver.value %> 
					<% if sys.value.ACFlightServer.value ~= "" then %>
					<span class="data-title"> | Served by : </span><%= sys.value.ACFlightServer.value %>
					<% else %>
					<span class="data-title"> | Served by : </span><%= sys.value.ACFminiServer.value %>
					<% end %>

				</p>
				<p class="dashboard-infos dash-info-user">
					<span class="data-title">User | </span><%= session.userinfo.userid %> &nbsp; <span class="data-title">Host | </span><%= hostname or "unknown hostname" %>
				</p>
		</div>
		<div class="data-block data-system-up-time">
			<span class="data-title">Uptime | </span>
				<span id="uptime" class="uptime">
				<% 
				local uptime = up_years .. " Years " .. up_mounths .. " Mounths " .. up_days .. " Days " .. up_hours .. "h " .. up_minutes .. "m " .. up_seconds .. "s"
				
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
				%>
				<%= uptime %>
		</span>
		</div>
	</div>
<!-- Dashboard App Block - LINE 1 -->
</div>

<!-- Dashboard App Block - LINE 2 -->
<div class="dashboard-main main-block">
<!-- Dashboard Main Block - SYSTEM - BLOCK 1 -->
	<div class="dashboard-hardware dashboard-block medium-block">
		<div class="data-block data-system">
			<h4 class="dashboard-block-title dashboard-title-hardware">Hardware</h4>
				<span class="icon-cpu">
					<% if string.find((proc.value.model.value), "Intel") then
						print ("<canvas class='icon-canvas-dash icon-cpu-intel'>''</canvas>")
					elseif string.find((proc.value.model.value), "AMD") then
						print ("<canvas class='icon-canvas-dash icon-cpu-amd'>''</canvas>")
					else
						print ("<canvas class='icon-canvas-dash icon-cpu-arm'>''</canvas>")
					end %>
				</span>
			<p class="dashboard-infos dash-info-board">
				<span class="data-title">Board : </span>
			<%
			-- EXEMPLE TO PARSE KNOW MOBO MODELS
			if string.match(sys.value.boardName.value, "EMB%-H81B") then
				print ("<span>" .. string.gsub(sys.value.boardVendor.value, "To be filled by O.E.M." or "Not Specified", "AAEON") .. "</span>")
				print (" | <span>" .. sys.value.boardName.value .. "</span> | ")
				print ("<span>" .. string.gsub(sys.value.boardVersion.value, "To be filled by O.E.M." or "Not Specified" or "Unknow", "Rev : 2.00") .. "</span>")
			-- ELSE REWRITE ALL OTHERS
			else
				print ("<span>" .. oem_parse(sys.value.boardVendor.value) .. "</span>")
				print (" | <span>" .. oem_parse(sys.value.boardName.value) .. "</span> | ")
				print ("<span>" .. version_parse(string.gsub(sys.value.boardVersion.value, "^", "Rev : ")) .. "</span>")
			end
			%>
			</p>
			<p class="dashboard-infos dash-info-bios">
				<span class="data-title">BIOS : </span>
					<span id="version">v. </span><%= sys.value.biosVersion.value %> | 
						<%= sys.value.biosVendor.value %> - 
							<%= sys.value.biosDate.value %>
			</p>
			<p class="dashboard-infos dash-info-cpu">
				<span class="data-title">CPU : </span><%= string.sub((proc.value.model.value), 14) %>
			</p>
			<p class="dashboard-infos dash-info-memory">
				<span class="data-title">Memory : </span>
					<%= bytesToSize(tonumber(sys.value.memory.totalData)) %> Total |
						<%= bytesToSize(tonumber(sys.value.memory.freeData)) %> Free | 
							<%= bytesToSize(tonumber(sys.value.memory.usedData)) %> Used 
			</p>
			<p class="dashboard-infos dash-info-network-lan">
				<span class="data-title">Lan IP : </span>
					<span class="value-title value-net-local"></span><%= netstats.value.eth0.ipaddr %> <!-- Need to review -->
			</p>
			<p class="dashboard-infos dash-info-network-wan">
				<span class="data-title">Wan IP : </span>
					<span class="value-title value-net-wan"></span><a href="https://ifconfig.me" target="_blank" title="🔗 https://ifconfig.me"><%= net.value.wanIP.value %><i class="fa-solid fa-up-right-from-square icon-listing"></i></a>
			</p>
			<p class="dashboard-infos dash-info-cpu-temp">
				<span class="data-title">CPU Temp</span>
			</p>
			<p class="dashboard-infos dash-info-temp">
			<%
			if (tonumber(proc.value.temp.value)) ~= nil then
			print (math.floor(tonumber(proc.value.temp.value / 1000)) .. "°C")
			else
			print ("N/A")
			end
			%>
			
			</p>
		</div>
	</div>
	
<!-- Dashboard Main Block - DISK - BLOCK 2 -->	
<div class="dashboard-main main-block medium-block">
	<div class="dashboard-memory dashboard-block">
		<h4 class="dashboard-block-title dashboard-title-disk">Disk</h4>
<!-- Dashboard Main Block - DISK CHART FROM N.ANGELACOS ACF NATIVE APP -->
	<% displaydisk = function(disk, name)
		io.write('<table id="legend-title" style="margin:0px;padding:0px;border:0px;margin-top:5px;">\n')
		io.write("	<tr>\n")
		io.write('		<td id="legend-object" width="100px"><b>'..html.html_escape(name)..'</b></td>\n')
		io.write("	</tr>\n")
		io.write("</table>\n")
		io.write('<table class="chart-bar chart-storage">\n')
		io.write("	<tr>\n")
		io.write("		<td>0%</td>\n")
	if tonumber(disk.used) > 0 then
		io.write('		<td id="capacity-used" class="capacity-used" width="'..html.html_escape(disk.used)..'%" style="')
	if tonumber(disk.used) < 100 then io.write('')
	end
		io.write('"><center><b>')
	if ( tonumber(disk.used) > 0) then io.write(html.html_escape(disk.used) .. "%") end
		io.write('</b></center></td>\n')
	end
	if tonumber(disk.used) < 100 then
		io.write('		<td id="capacity-free" class="capacity-free" width="'..(100-tonumber(disk.used))..'%" style="')
	if tonumber(disk.used) > 0 then io.write('') 
		end
		io.write('"><center><b>')
	if ( 100 > tonumber(disk.used)) then io.write((100-tonumber(disk.used)) .. "%") end
		io.write('</b></center></td>\n')
	end
		io.write('		<td>100%</td>\n')
		io.write("	</tr>\n")
		io.write("</table>\n")
	end
	if (disk.value.hd) then
			for name,hd in pairs(disk.value.hd.value) do
				displaydisk(hd, name)
	end
	else %>
<p class="error error-txt">No Hard Drive Mounted</p>
<% end %>
<% if (disk.value.ramdisk) then
			for name,ramdisk in pairs(disk.value.ramdisk.value) do
				displaydisk(ramdisk, name)
	end
	else %>
<p class="error error-txt">No RamDisk Mounted</p>
<% end %>
	</div>
</div>

<!-- Dashboard Main Block - MEMORY - BLOCK 3 -->
<div class="dashboard-main main-block small-block">
	<div class="dashboard-memory dashboard-block">
		<h4 class="dashboard-block-title dashboard-title-memory">Memory</h4>
<!-- Dashboard Main Block - CHART.JS -->
		<div class="chart-canvas chartjs">
				<canvas id="memoryChart" class="data-chart block-chart"></canvas>
		</div>
			<p class="legend-memory-free"><span class="corporate-blue"><%= sys.value.memory.free %><sup>%</sup></span>
			</p>
		<div class="data-block data-memory">
			<p class="data">
				<span class="data-title">Memory : </span>
					<span class="data-mem-total"><%= bytesToSize(tonumber(sys.value.memory.totalData)) %> Total</span> |
						<span class="data-mem-free"><%= bytesToSize(tonumber(sys.value.memory.freeData)) %> Free</span> | 
							<span class="data-mem-used"><%= bytesToSize(tonumber(sys.value.memory.usedData)) %> Used</span>
			</p>
		</div>
		
<!-- Dashboard Main Block - MEMORY CHART.JS -->		
<script type="application/javascript" defer>
$(function memChart() {
// Setup Block
	var memFree = <%= json.encode(sys.value.memory.free) %>;
	var memBuff = <%= json.encode(sys.value.memory.buffers) %>;
	var memUsed = <%= json.encode(sys.value.memory.used) %>;
	const data = {
		labels: ['Free', 'Buffured', 'Used'],
		datasets: [{
			label: 'Memory Status',
			borderWidth: 4,
			data: [memFree, memBuff, memUsed]
		}]
	};
// Config Block
	const config = {
		type: 'doughnut',
		data,
		options: {
			borderColor: '#fbfbfb',
			responsive: true,
			maintainAspectRatio: false,
			rotation: -135,
			circumference: 270,
			backgroundColor: [
                    '#16597A',
                    '#0075af',
                    '#cbcbcb'
			]
		}
    };
// Render Block
	const memoryChart = new Chart(
		document.getElementById('memoryChart'),
		config
	)
});
	</script>	
		</div>
	</div>
<!-- Dashboard App Block - LINE 2 -->
</div>
<!-- Dashboard App Block - LINE 3 -->
<div class="dashboard-main main-block">
<!-- Dashboard Main Block - 1 -->
	<div class="dashboard-block large-block dashboard-network">
		<div class="data-block data-system">
			<h4 class="dashboard-block-title dashboard-title-network-stats">Network Stats</h4>
			<div id="chartNetwork"> </div>
			<canvas id="networkChart" class="data-chart block-chart"></canvas>
		</div>
<div id="demo"></div>

<!-- Dashboard Main Block - NETWORK CHART.JS -->
<script type="application/javascript" src="https://cdn.jsdelivr.net/npm/luxon@latest"></script>
<script type="application/javascript" src="https://cdn.jsdelivr.net/npm/chartjs-adapter-luxon@latest/dist/chartjs-adapter-luxon.umd.min.js"></script>
<script type="application/javascript" src="https://cdn.jsdelivr.net/npm/chartjs-plugin-streaming@latest"></script>		
<script type="application/javascript" defer>
	var interval = 1000;
	var duration = 60000;
	var lastdata = <%= json.encode(netstats) %>;
	var chartdata = <% -- Generate the data structure in Lua and then convert to json
			local chartdata = {}
			for i,intf in ipairs(interfaces) do
				chartdata[intf.."RX"] = {label=intf.." RX", data={}, color=rgb[i][1]}
				chartdata[intf.."TX"] = {label=intf.." TX", data={}, color=rgb[i][2]}
			end
			io.write( json.encode(chartdata) ) %>;
	
   function displayStats() {
   $.ajaxSetup({cache:false});
   $.getJSON(
     '<%= html.html_escape(page_info.script .. "/alpine-baselayout/health/networkstats") %>', {viewtype:'json'}, 
	function(data) {
				if (lastdata != null){
					if (data.timestamp <= lastdata.timestamp) return false;
					var timestamp = data.timestamp * 1000;
					var multiplier = 1 / (data.timestamp - lastdata.timestamp);
					var shiftcount = null;
					$.each(lastdata.value, function(key,val){
						chartdata[key+"RX"].data.push([timestamp, (data.value[key].RX.bytes - lastdata.value[key].RX.bytes)*multiplier]);
						chartdata[key+"TX"].data.push([timestamp, (data.value[key].TX.bytes - lastdata.value[key].TX.bytes)*multiplier]);
						if (shiftcount == null) {
							shiftcount = 0;
							$.each(chartdata[key+"RX"].data, function(key,val){
								if (val[0] < timestamp-duration)
									shiftcount += 1;
								else
									return false;
							});
						}
						for (i=0; i<shiftcount; i++){
							chartdata[key+"RX"].data.shift();
							chartdata[key+"TX"].data.shift();
						}
					});
				}
				lastdata = data;
				document.getElementById("demo").innerHTML = JSON.stringify(lastdata.value.eth0);
			});
};
	setInterval(displayStats, 1000);
$(function networkChart() {
// Setup Block
	const data = {
      labels: [],
      datasets: [{
        label: 'RX eth0',
        data: [],
        tension: 0.25,
		fill: true,
		pointRadius: 0
      },
	  {
        label: 'TX eth0',
        data: [],
        tension: 0.25,
		fill: true,
		pointRadius: 0
      }],
    };
// Config Block
	const config = {
		type: 'line',
		data,
		options: {
			streaming: {
				frameRate: 30  // chart is drawn 5 times every second
      },
		  scales: {
			x: {
				type: 'realtime',
				realtime: {
				    duration: 40000,
					refresh: 1000,
					delay: 500,
					onRefresh: chart => {
						chart.data.datasets.forEach(dataset => {
							dataset.data.push({
							x: Date.now(),
							y: setInterval(JSON.stringify(lastdata.value.eth0), 1000)
							});
						})
					}
				}
			},
			y: {
			}
		  }
		}
	  };
// Render Block
	const networkChart = new Chart(
		document.getElementById('networkChart'),
		config
	);
});

</script>

		<div>
	</div>
</div>
<!-- Dashboard App Block - LINE 3 -->
</div>
<!-- Dashboard App Block - LINE 4 -->
<div class="dashboard-main main-block">
<!-- Dashboard Main Block - DISK & PARTITION 1 -->
	<div class="dashboard-ssh dashboard-block large-block">
		<div class="data-block data-diskpart">
			<h4 class="dashboard-block-title dashboard-title-disk-viewer">Disk | Partition Viewer</h4>
				<p class="dashboard-infos dash-info-keys">
					<span class="data-title">List of Hardware Disk : </span>
					</p>
					<% 
					local physicalDisk = string.match(disk.value.partitions.value, "(sd%a)")
					local physicalCapacity = string.gsub(string.match(disk.value.partitions.value, "(%d+.sd%a)"), "%D", "")
					%>
						<div class="section-disk" id="disk-partition-view">
							<div id="partition-table">
								<%= physicalDisk %> : <%= blocksToSize(tonumber(physicalCapacity) * 1024) %>
							</div>
							</div>
							<pre>
							<%= disk.value.partitions.value %>
							</pre>
		</div>
	</div>
<!-- Dashboard App Block - LINE 4 -->
</div>
<% --[[
	io.write(htmlviewfunctions.cfe_unpack(view))
	io.write(htmlviewfunctions.cfe_unpack(FORM))
	io.write(htmlviewfunctions.cfe_unpack(ENV))
--]] %>

<% htmlviewfunctions.displaysectionend(header_level) %>