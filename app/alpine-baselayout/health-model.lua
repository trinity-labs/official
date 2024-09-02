local mymodule = {}

fs = require("acf.fs")
date = require("acf.date")
format = require("acf.format")
modelfunctions = require("modelfunctions")

-- ###############################################################
-- Private functions
-- ###############################################################

local function querycmd ( cmdline )
	local cmd_result = modelfunctions.run_executable(format.string_to_table(cmdline, "%s+"))
	if not cmd_result or cmd_result == "" then
		cmd_result = "unknown"
	end
	return cmd_result
end

local function querycmdextended ( cmdline )
	local cmd_result = modelfunctions.run_executable({cmdline})
	if not cmd_result or cmd_result == "" then
		cmd_result = ( cmdline )
	end
	return cmd_result
end

local function indexversion ()
	local cmd_result = modelfunctions.run_executable({"apk", "version", "--index"})
	if cmd_result == "" then cmd_result = nil end
	return cmd_result
end

local function diskfree ( media )
	local cmd_result = modelfunctions.run_executable({"df", media})
	if not cmd_result or cmd_result == "" then
		cmd_result = "unknown"
	end
	return cmd_result
end

local function disklist ()
	local cmd_result = modelfunctions.run_executable({"fdisk", "-l"})
	if not cmd_result or cmd_result == "" then
		cmd_result = "unknown"
	end
	return cmd_result
end

local function memusage ()
	local mult = { kB=1024, MB=1048576, GB=1073741824 }
	local fd = io.open("/proc/meminfo")
	local res = {}
	local field, value, unit
	for line in fd:lines() do
		field, value, unit = string.match(line, "([^: ]*):%s*(%d+)%s(%a+)")
		if field ~= nil and value ~= nil then
			res[field] = tonumber(value)
			if unit ~= nil then
				res[field] = res[field] * mult[unit]
			end
		end
	end
	fd:close()
	return res
end

local function findThermalPkg()
    local cmd = io.popen('cat /sys/class/thermal/thermal_zone*/type')
    local search = "x86_pkg_temp"
    local pkgPosition = nil
    local i = -1
    for line in cmd:lines() do
        i = i + 1
        if line == search then
            pkgPosition = i
            break
        end
    end
    cmd:close()
    return pkgPosition
end

local function findThermalBoard()
    local cmd = io.popen('cat /sys/class/thermal/thermal_zone*/type')
    local search = "acpitz"
    local boardPosition = nil
    local i = -1
    for line in cmd:lines() do
        i = i + 1
        if line == search then
            boardPosition = i
            break
        end
    end
    cmd:close()
    return boardPosition
end

local function parse_disk_models(output)
    local disks = {}
    for disk_output in output:gmatch("Disk%s+/dev/%S+:%s+.-\n\n") do
        local disk_path = disk_output:match("Disk%s+(/dev/%S+):")
        local disk_size = disk_output:match("Disk%s+/dev/%S+:%s+([^,]+)")
        local disk_model = disk_output:match("Disk model:%s+([^\n]+)")
        if disk_path and disk_size and disk_model then
            table.insert(disks, {
                path = disk_path,
                size = disk_size,
                model = disk_model
            })
        end
    end
    return disks
end

-- ###############################################################
-- Public functions
-- ###############################################################

mymodule.get_system = function (self)
	local system = {}
	local meminfo = memusage()
	local diskinfo = disklist()
	local indexver = indexversion()
	system.uptime = cfe({ value=querycmd("cat /proc/uptime"), label="Uptime" })
	system.date = cfe({ value=querycmd("date"), label="Date" })
	system.alpinever = cfe({ value=querycmd("wget -qO- https://www.alpinelinux.org/releases.json ; echo") or "Unknown", label="Check Alpine Version" })
	system.alpineposts = cfe({ value=querycmd("wget -qO- https://www.alpinelinux.org/posts/ ; echo"), label="Get Version Changes" })
	system.version = cfe({ value=querycmd("cat /etc/alpine-release") or "Unknown", label="Version" })
	system.alpineluaver = cfe({ value=string.match(querycmd("cat /usr/share/acf/www/cgi-bin/acf") or "Unknown", "lua%d.%d") or "Unknown", label="Alpine Lua Version" })
	system.luaver = cfe({ value=string.match(querycmd((system.alpineluaver.value) .. " -v") or "Unknown", "Lua%s%d.%d.%d") or "Unknown", label="Lua Version" })
	system.ACFnginxServer = cfe({ value=querycmd("nginx -V") or "", label="ACF Nginx Server" })
	system.ACFlightServer = cfe({ value=string.match(querycmd("lighttpd -v"), ".+%d+.%d+%p%d+") or "", label="ACF Lighttpd Server" })
	system.ACFminiServer = cfe({ value=string.match(querycmd("mini_httpd -V"), ".+%d+%p%d+") or "", label="ACF Mini_Httpd Server" })
	system.timezone = cfe({ value=date.what_tz(), label="Time Zone" })
	system.uname = cfe({ value=querycmd("uname -a"), label="UName" })
	system.kernel = cfe({ value=querycmd("uname -r"), label="Kernel" })
	system.memory = cfe({ value=querycmd("free"), label="Memory usage" })
	system.memory.totalData = string.format("%.2f", (meminfo["MemTotal"]))
	system.memory.freeData = string.format("%.2f", (meminfo["MemAvailable"]))
	system.memory.usedData = string.format("%.2f", (meminfo["MemTotal"] - meminfo["MemAvailable"]))
	system.memory.free = math.floor(100 * (meminfo["MemFree"]) / meminfo["MemTotal"])
	system.memory.buffers = math.floor(100 * (meminfo["Buffers"] + meminfo["Cached"]) / meminfo["MemTotal"])
	system.memory.used = 100 - math.floor(100 * (meminfo["MemFree"] + meminfo["Buffers"] + meminfo["Cached"]) / meminfo["MemTotal"])
	system.drivelist = cfe({ value=querycmd("fdisk -l") or "Unknown", label="Board Name" })
	system.boardName = cfe({ value=querycmd("cat /sys/devices/virtual/dmi/id/board_name") or "Unknown", label="Board Name" })
	system.boardVendor = cfe({ value=querycmd("cat /sys/devices/virtual/dmi/id/board_vendor") or "Unknown", label="Board Vendor" })
	system.boardVersion = cfe({ value=querycmd("cat /sys/devices/virtual/dmi/id/board_version") or "Unknown", label="Board Version" })
	system.biosVendor = cfe({ value=querycmd("cat /sys/devices/virtual/dmi/id/bios_vendor") or "Unknown", label="Bios Vendor" })
	system.biosVersion = cfe({ value=querycmd("cat /sys/devices/virtual/dmi/id/bios_version") or "Unknown", label="Bios Version" })
	system.biosDate = cfe({ value=string.match(querycmd("cat /sys/devices/virtual/dmi/id/bios_date"), "%d%d%d%d") or "Unknown", label="Bios Date" })
	return cfe({ type="group", value=system, label="System" })
end

mymodule.get_storage = function(self)
    local storage = {}
    local disk = diskfree() .. "\n"
    local fdisk_output = disklist()
    local disks = parse_disk_models(fdisk_output)
    local other = {}
    local lines = format.string_to_table(disk, "\n")
    local i = 1  -- skip the first line

    while i < #lines do
        i = i + 1
        line = lines[i] or ""
        if lines[i + 1] and string.match(lines[i + 1], "^%s") then
            i = i + 1
            line = line .. "\n" .. lines[i]
        end
        if string.match(line, "^/dev/fd%d+") then
            if not storage.floppy then
                storage.floppy = cfe({ type = "group", value = {}, label = "Floppy drives" })
            end
            local name = string.match(line, "^(/dev/fd%d+)")
            storage.floppy.value[name] = cfe({ value = string.match(disk, "[^\n]*\n") .. line, label = "Floppy Capacity" })
            storage.floppy.value[name].used = string.match(line, name .. "%s*%S*%s*%S*%s*%S*%s*(%S*)%%")
        elseif string.match(line, "^/dev/none") or string.match(line, "^tmpfs") then
            if not storage.ramdisk then
                storage.ramdisk = cfe({ type = "group", value = {}, label = "RAM disks" })
            end
            local name = string.match(line, "^(%S+)")
            storage.ramdisk.value[name] = cfe({ value = string.match(disk, "[^\n]*\n") .. line, label = "RAM Disk Capacity" })
            storage.ramdisk.value[name].used = string.match(line, name .. "%s*%S*%s*%S*%s*%S*%s*(%S*)%%")
        elseif (string.match(line, "^/dev/") or string.match(line, ":")) and not string.match(line, "^/dev/cdrom") and not string.match(line, "^/dev/loop") then -- Find rclone mount point
            if not storage.hd then
                storage.hd = cfe({ type = "group", value = {}, label = "Hard drives" })
            end
            local name = string.match(line, "^(%S+)")
            local hd_entry = cfe({ value = string.match(disk, "[^\n]*\n") .. line, label = "Hard Drive Capacity" })
			hd_entry.size = string.match(line, name .. "%s+(%S+)")
			hd_entry.use = string.match(line, name .. "%s+%S+%s+(%S+)")
			hd_entry.available = string.match(line, name .. "%s+%S+%s+%S+%s+(%S+)")
			hd_entry.used = string.match(line, name .. "%s+%S+%s+%S+%s+%S+%s+(%d+)%%")
			hd_entry.mount_point = string.match(line, name .. "%s+%S+%s+%S+%s+%S+%s+%S+%s+(%S+)$")
            -- Match with the fdisk parsed data to add the model information
            for _, disk_info in ipairs(disks) do
                if name:match(disk_info.path) then
                    hd_entry.model = disk_info.model
                    break
                end
            end
            storage.hd.value[name] = hd_entry
        end
    end
    -- Add partitions info from /proc/partitions
    storage.partitions = cfe({ value = fs.read_file("/proc/partitions") or "", label = "Partitions" })

    return cfe({ type = "group", value = storage, label = "Storage" })
end

mymodule.get_network = function (self)
	local network = {}
	network.lanIP = cfe({ value=querycmd("ip route"), label="LAN IP" })
	network.wanIP = cfe({ value=querycmd("wget -qO- https://ifconfig.me ; echo") or "Unknow", label="WAN IP" })
	network.interfaces = cfe({ value=querycmd("ip addr"), label="Interfaces" })
	network.PhysicalIfaces = cfe({ value=querycmd("ip a"), label="Physical Interfaces" })
	network.routes = cfe({ value=querycmd("ip route"), label="Routes" })
	network.tunnel = cfe({ value=querycmd("ip tunnel"), label="Tunnels" })
	return cfe({ type="group", value=network, label="Network" })
end

mymodule.get_proc = function (self)
	local proc = {}
	proc.processor = cfe({ value=fs.read_file("/proc/cpuinfo") or "", label="Processor" })
	proc.memory = cfe({ value=fs.read_file("/proc/meminfo") or "", label="Memory" })
	proc.model = cfe({ value=querycmd("sed -n 5p /proc/cpuinfo") or "", label="CPU Model" })
	proc.gpu = cfe({ value=string.match(querycmd("lspci"), "VGA compatible controller:(%s+%w+%s+%w+%s+%w+%s+%w+)") or "Unknow", label="VGA GPU" })
	return cfe({ type="group", value=proc, label="Hardware Information" })
end

mymodule.get_api = function (self)
	local api = {}
	local meminfo = memusage()
	local pkgPosition = findThermalPkg()
	local boardPosition = findThermalBoard()
	api.cpuTemp = cfe({ value=querycmd("cat /sys/class/thermal/thermal_zone"..pkgPosition.."/temp") or "N/A", label="CPU Temp" })
	api.boardTemp = cfe({ value=querycmd("cat /sys/class/thermal/thermal_zone"..boardPosition.."/temp") or "N/A", label="Board Temp" })
	api.memory = cfe({ value=querycmd("free"), label="Memory usage" })
	api.memTotal = string.format("%.2f", (meminfo["MemTotal"]) / 1073741824)
	api.memFree = string.format("%.2f", (meminfo["MemFree"]) / 1073741824)
	api.memUsed = string.format("%.2f", (meminfo["MemTotal"] - meminfo["MemAvailable"]) / 1073741824)
	api.disk = cfe({ value=querycmd("fdisk -l"), label="Disk List" })
	return cfe({ type="group", value=api, label="Hardware API" })
end

mymodule.get_networkstats = function ()
	local stats = cfe({ type="structure", value={}, label="Network Statistics", timestamp=os.time() })
	local result = fs.read_file("/proc/net/dev") or ""
	-- parse the result
	local i=0
	for line in string.gmatch(result, "[^\n]+\n?") do
		if i>1 then
			local intf = string.match(line, "([^%s:]+):")
			line = string.match(line, ":(.*)$")
			local words = {}
			for word in string.gmatch(line, "%S+") do
				words[#words+1] = word
			end
			stats.value[intf] = {}
			stats.value[intf].RX = {bytes=words[1], packets=words[2]}
			stats.value[intf].TX = {bytes=words[9], packets=words[10]}
		end
		i=i+1
	end
	return stats
end

return mymodule