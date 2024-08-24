<% local view, viewlibrary, page_info, session = ... %>
<% json = require("json") %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>
<%
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
	for intf in pairs(view.value) do table.insert(interfaces, intf) end
	table.sort(interfaces)
%>

<style type="text/css">
	#chart table {
		width: auto;
	}
</style>
<!--[if IE]><script type="text/javascript" src="<%= html.html_escape(page_info.wwwprefix) %>/js/excanvas.js"></script><![endif]-->
<script type="text/javascript">
	if (typeof jQuery == 'undefined') {
		document.write('<script type="text/javascript" src="<%= html.html_escape(page_info.wwwprefix) %>/js/jquery-latest.js"><\/script>');
	}
</script>

<script type="text/javascript">
        if (typeof $.plot == 'undefined') {
                document.write('<script type="text/javascript" src="<%= html.html_escape(page_info.wwwprefix) %>/js/jquery.flot.js"><\/script>');
        }
</script>

<script type="text/javascript">
        if (typeof $.plot.formatDate == 'undefined') {
                document.write('<script type="text/javascript" src="<%= html.html_escape(page_info.wwwprefix) %>/js/jquery.flot.time.js"><\/script>');
        }
</script>

<script type="text/javascript">
	var interval = 1000;
	var duration = 60000;
	var lastdata = <%= json.encode(view) %>;
	var chartdata = <% -- Generate the data structure in Lua and then convert to json
			local chartdata = {}
			for i,intf in ipairs(interfaces) do
				chartdata[intf.."RX"] = {label=intf.." RX", data={}, color=rgb[i][1]}
				chartdata[intf.."TX"] = {label=intf.." TX", data={}, color=rgb[i][2]}
			end
			io.write( json.encode(chartdata) ) %>;
	var ID
	function DrawChart(){
		var data = [];
		$("body").find("input:checked").each(function() {
			data.push(chartdata[$(this).attr("name")]);
		});
		var timestamp = 0;
		$.each(chartdata, function(key,val){
			if (val.data.length > 0){
				timestamp=val.data[0][0];
				return false;
			}
		});
		if (timestamp == 0 && lastdata != null) timestamp = lastdata.timestamp*1000;
		$.plot(
			$("#chart"), data, {legend:{show:false}, xaxis:{mode:"time", timeformat:"%H:%M:%S", min:timestamp, max:timestamp+duration}, yaxis:{min:0}});
	}
	function Update(){
		$.ajaxSetup({cache:false});
		$.getJSON(
			'<%= html.html_escape(page_info.script .. page_info.prefix .. page_info.controller .. "/" .. page_info.action) %>',
			{viewtype:'json'},
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
				DrawChart();
			}
		);
	}
	function Start(){
		lastdata = null;
		$.each(chartdata, function(key,val){
			val.data = [];
		});
		Update();
		ID = window.setInterval("Update()", interval);
		$("#Start").attr("disabled","disabled");
		$("#Stop").removeAttr("disabled");
	}
	function Stop(){
		window.clearInterval(ID);
		$("#Stop").attr("disabled","disabled");
		$("#Start").removeAttr("disabled");
	}
	$(function (){
	   	$(":checkbox").click(DrawChart);
		$("#Start").click(Start);
		$("#Stop").click(Stop);
		DrawChart();
		Start();
	});
</script>

<% local header_level = htmlviewfunctions.displaysectionstart(view, page_info) %>
<p>Network traffic in bytes/second</p>
<div id="chart" style="width:680px; height:300px;"></div>

<% htmlviewfunctions.displayitemstart() %>
Display Options
<% htmlviewfunctions.displayitemmiddle() %>
<table class="tablesorter"><thead>
<tr><th>Interface</th><th>IP Address</th><th colspan="2">RX</th><th colspan="2">TX</th></tr>
</thead><tbody>
<% for i,intf in ipairs(interfaces) do %>
	<tr><td><%= html.html_escape(intf) %></td><td><%= html.html_escape(view.value[intf].ipaddr) %></td>
	<td><input type="checkbox" name="<%= html.html_escape(intf) %>RX" checked="checked"></td>
	<td><div style="width:14px;height:10px;border:1px solid #ccc;padding:1px"><div style="width:14px;height:10px;background-color:<%= rgb[i][1] %>;overflow:hidden"></div></div></td>
	<td><input type="checkbox" name=<%= html.html_escape(intf) %>TX checked="checked"></td>
	<td><div style="width:14px;height:10px;border:1px solid #ccc;padding:1px"><div style="width:14px;height:10px;background-color:<%= rgb[i][2] %>;overflow:hidden"></div></div></td></tr>
<% end %>
</tbody></table>
<% htmlviewfunctions.displayitemend() %>

<% htmlviewfunctions.displayitemstart() %>
Start / Stop
<% htmlviewfunctions.displayitemmiddle() %>
<input class="submit" type="button" id="Start" value="Start">
<input class="submit" type="button" id="Stop" value="Stop">
<% htmlviewfunctions.displayitemend() %>

<% --[[ -- display table of colors %>
<table style="width:auto;">
<% for i=1,#rgb do %>
<tr><td><div style="border:1px solid #ccc;padding:1px"><div style="width:14px;height:10px;background-color:<%= rgb[i][1] %>;overflow:hidden"></div></div></td>
<td><div style="border:1px solid #ccc;padding:1px"><div style="width:14px;height:10px;background-color:<%= rgb[i][2] %>;overflow:hidden"></div></div></td></tr>
<% end %>
</table>
<% --]] %>

<% htmlviewfunctions.displaysectionend(header_level) %>
