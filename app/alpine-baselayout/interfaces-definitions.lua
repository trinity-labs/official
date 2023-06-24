local mymodule = {}
-- Definitions of interface cfe's / options
	mymodule.required = {
		comment = {type="longtext", label="Comments", seq=2},
		auto = {type="boolean", value=false, label="Auto bring-up", seq=3},
		name = {label="Interface Name", seq=1},
		family = {type="select", label="Address Family", option={"inet", "ipx", "inet6"}, seq=4},
		method = {type="select", label="Method", option={"loopback", "static", "manual", "dhcp", "bootp", "ppp", "wvdial", "dynamic", "v4tunnel"}, seq=5},
		['pre-up'] = {type="longtext", label="'pre-up' actions", seq=100},
		up = {type="longtext", label="'up' actions", seq=101},
		down = {type="longtext", label="'down' actions", seq=102},
		['post-down'] = {type="longtext", label="'post-down' actions", seq=103},
		other = {type="longtext", label="Other options (unsupported)", seq=104},
	}
	mymodule.family_methods = {
		inet = {"loopback", "static", "manual", "dhcp", "bootp", "ppp", "wvdial"},
		ipx = {"static", "dynamic"},
		inet6 = {"loopback", "static", "manual", "v4tunnel"},
	}
	mymodule.method_options = {
		inet = {
			static = {"address", "netmask", "broadcast", "network", "metric", "gateway", "pointopoint", "media", "hwaddress", "mtu"},
			dhcp = {"hostname", "leasehours", "leasetime", "vendor", "client", "hwaddress"},
			bootp = {"bootfile", "server", "hwaddr"},
			ppp = {"provider"},
			wvdial = {"provider"},
		},
		ipx = {
			static = {"frame", "netnum"},
			dynamic = {"frame"},
		},
		inet6 ={
			static = {"address", "netmask", "gateway", "media", "hwaddress", "mtu"},
			v4tunnel = {"address", "netmask", "endpoint", "local", "gateway", "ttl"},
		},
	}
	mymodule.optional = {
		address = {label="Address", seq=6},
		netmask = {label="Netmask", seq=7},
		endpoint = {label="Endpoint address", seq=8},
		['local'] = {label="Local address", seq=9},
		broadcast = {label="Broadcast address", seq=10},
		network = {label="Network address", seq=11},
		metric = {label="Routing metric", seq=12},
		gateway = {label="Default gateway", seq=13},
		pointopoint = {label="Point-to-point address", seq=14},
		media = {label="Medium type", seq=15},
		hostname = {label="Hostname", seq=16},
		leasehours = {label="Preferred lease time (hours)", seq=17},
		leasetime = {label="Preferred lease time (seconds)", seq=18},
		vendor = {label="Vendor class identifier", seq=19},
		client = {label="Client identifier", seq=20},
		hwaddress = {label="Hardware address", seq=21},
		mtu = {label="MTU size", seq=22},
		bootfile = {label="Boot file", seq=23},
		server = {label="Server address", seq=24},
		hwaddr = {label="Hardware address", seq=25},
		provider = {label="Provider name", seq=26},
		frame = {label="Ethernet frame type", seq=27},
		netnum = {label="Network number", seq=28},
		ttl = {label="TTL setting", seq=29},
	}

return mymodule
