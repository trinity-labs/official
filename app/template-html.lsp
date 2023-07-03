<% local viewtable, viewlibrary, pageinfo, session = ...
   html=require("acf.html")
   posix=require("posix")
%>
Status: 200 OK
Content-Type: text/html
<%
if (session.id) then
	io.write( html.cookie.set("sessionid", session.id) )
else
	io.write (html.cookie.unset("sessionid"))
end
%>

<%
local hostname = ""
if session.userinfo and session.userinfo.userid and viewlibrary and viewlibrary.dispatch_component then
	local result = viewlibrary.dispatch_component("alpine-baselayout/hostname/read", nil, true)
	if result and result.value then
		hostname = result.value
	end
end
%>

<!DOCTYPE html>
<!-- 
==============================================================
      🟦 Alpine Linux Admin Dashboard | v 1.0.0 - ACF
==============================================================
* Product Page: ACF Dashboard Skin (https://gitlab.alpinelinux.org/trinity-labs/dashboard-skin)
* Created by: T. Bonnin for Alpine Configuration Framework (ACF) based on N. Angelacos previous work
* License: Licensed under the terms of GPL2
* Copyright : (C) 2007 N. Angelacos for ACF - (C) 2023 T. Bonnin for DashBoard App
* Exclusive Features :
	+ Can run on memory only (stock in Alpine)
	+ No Database
	+ No PHP
	+ No config nested with front-end server
	+ CGI-Script with Lua 5.4 packed in lsp - (https://github.com/LuaLS/lua-language-server)
	+ JS CDN layered without needed to install Node npm
* Feel free to colaborate, modify and share all part of this template !
* If it's for commercial use, please, feedback your dev to the community
==============================================================
  ** This file is write in Lua 5.4 for haserl-lua5.4.apk **
==============================================================
-->
<!--[if IE 6]> <html class="ie6"> <![endif]-->
<!--[if IE 7]> <html class="ie7"> <![endif]-->
<!--[if IE 8]> <html class="ie8"> <![endif]-->
<!--[if gt IE 8]><!--> <html class="app-<%= pageinfo.action %>"> <!--<![endif]-->
<head>
		<meta charset="utf-8">
		<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<meta name="theme-color" content="#16597a">
		<meta name="apple-mobile-web-app-capable" content="yes">
		<meta name="apple-mobile-web-app-status-bar-style" content="#16597a">
<% if pageinfo.skinned ~= "false" then %>
<% if session.userinfo and session.userinfo.userid and viewlibrary and viewlibrary.dispatch_component then %>
		<title><%= html.html_escape(string.upper(hostname) .. " - " .. string.gsub(pageinfo.controller, "^%l", string.upper) .. " ∣ " .. string.gsub(pageinfo.action, "^%l", string.upper)) %></title>
<% else %>
		<title><%= html.html_escape(string.gsub(pageinfo.controller, "^%l", string.upper) .. " ∣ " .. string.gsub(pageinfo.action, "^%l", string.upper)) %></title>
<% end %>
		<link rel="icon" href="/skins/dashboard/favicon.ico" />
		<link rel="stylesheet" type="text/css" href="<%= html.html_escape(pageinfo.wwwprefix..pageinfo.staticdir) %>/reset.css">
		<link rel="stylesheet" type="text/css" href="<%= html.html_escape(pageinfo.wwwprefix..pageinfo.skin.."/"..posix.basename(pageinfo.skin)..".css") %>">
		<!--[if IE]>
		<link rel="stylesheet" type="text/css" href="<%= html.html_escape(pageinfo.wwwprefix..pageinfo.skin.."/"..posix.basename(pageinfo.skin).."-ie.css") %>">
		<![endif]-->
		<!-- UNPKG JS CDN FOR LATEST CHART.JS -->
		<script type="application/javascript" src="https://unpkg.com/chart.js@latest/dist/chart.umd.js"></script>
		<script type="application/javascript" src="https://cdn.jsdelivr.net/npm/luxon@latest"></script>
		<script type="application/javascript" src="https://cdn.jsdelivr.net/npm/chartjs-adapter-luxon@latest/dist/chartjs-adapter-luxon.umd.min.js"></script>
		<script type="application/javascript" src="https://cdn.jsdelivr.net/npm/chartjs-plugin-streaming@latest"></script>
		<!-- UNPKG JS CDN FOR LATEST HIGHLIGHT.JS -->
		<script type="application/javascript" src="https://unpkg.com/@highlightjs/cdn-assets@latest/highlight.min.js"></script>
		<!-- INITIALIZE HIGHLIGHT.JS -->
		<script type="application/javascript" defer>hljs.highlightAll()</script>
		<!-- UNPKG JS CDN FOR LATEST JQUERY -->
		<script type="application/javascript" src="https://unpkg.com/jquery"></script>
		<script type="text/javascript" src="<%= html.html_escape(pageinfo.wwwprefix..pageinfo.skin.."/"..posix.basename(pageinfo.skin)..".js") %>"></script>
		<script type="text/javascript">
			$(function(){
				$(":input:not(input[type=button],input[type=submit],button):enabled:not([readonly]):visible:first").focus();
			});
	
			$(document).ready(function() {
				// Login page input placeholder
				if(window.location.href.indexOf("logon/logon") > -1){
					document.querySelector('#userid input').setAttribute('required','required');
					document.querySelector('#password input').setAttribute('required','required');
					document.querySelector('#userid input').setAttribute('placeholder','🔒 User ID');
					document.querySelector('#password input').setAttribute('placeholder','🔑 Password');
					document.querySelector('#login').setAttribute('autocomplete','on');
				
					document.querySelector('#password input').setAttribute('autocomplete','off');
					document.querySelector('.hidden').setAttribute('hidden','');
			};
			// Save collapse menu state 
				var updated = window.localStorage.getItem('nav', updated);	
				
			if (window.localStorage.getItem('nav') === 'active') {
				nav.style.display = "block";
				content.style.width = "80%";
				subnav.style.width = "80%";
			} else {
				content.style.width = "100%";
				subnav.style.width = "100%";
			};
			
			if (updated === '') {
				window.localStorage.setItem('nav', 'active');
				$("#nav").toggleClass("active");
				$("#toogle").toogleClass("active");
			} else {
				window.localStorage.getItem('nav', updated);
				$("#nav").toggleClass(updated);
				$("#toogle").toggleClass(updated);
			}
			});
	
			// Toogle collapse menu
			function toogleMenu() {  
				var updated = window.localStorage.getItem('nav', updated);
				$("#nav").toggleClass("active");
				$("#toogle").toggleClass("active");
			if (window.localStorage.getItem('nav') === 'active') {
				updated = 'not_active';
				nav.style.display = "none";
				$("#content").animate({width: '100%'});
				$("#subnav").animate({width: '100%'});
				$("#nav").toggleClass("not_active");
				$("#toogle").toggleClass("not_active");
			} else {
				updated = 'active';
				$("#nav").slideToggle(900);
				$("#nav").removeClass("not_active");
				$("#toogle").removeClass("not_active");
				nav.style.display = "block";
				$("#content").animate({width: '80%'});
				$("#subnav").animate({width: '80%'});
				
			}
			window.localStorage.setItem('nav', updated);
		};
		</script>
</head>
		<% end -- pageinfo.skinned %>
<%
	local class
	local tabs
	if (#session.menu.cats > 0) then
		for x,cat in ipairs(session.menu.cats) do
			for y,group in ipairs(cat.groups) do
				if not tabs and group.controllers[pageinfo.prefix .. pageinfo.controller] then
				tabs = group.tabs
%>
<body id="<%= html.html_escape(cat.name) %>" class="<%= pageinfo.controller.." "..pageinfo.controller.."-"..pageinfo.action %>">	
<% 
				end
			end
		end
	end 
%>
	
<body class="<%= pageinfo.controller.." "..pageinfo.controller.."-"..pageinfo.action %>">
	
<% if pageinfo.skinned ~= "false" then %>

<header id="header">

				<%
					local ctlr = pageinfo.script .. "/acf-util/logon/"

					if session.userinfo and session.userinfo.userid then
						print("<a href='javascript:void(0);' class='icon' id='toogle-link' title='Menu' onclick='toogleMenu()'><div id='toogle'><i class='fa-solid fa-bars'></i></div></a>")
						print("<div id='header-links'><a id='logoff' class='icon-header' title='Logoff' href=\""..html.html_escape(ctlr).."logoff\"><i class='fa-solid fa-user-lock fa-2x logoff-icon'></i></a>")
						print("<a id='home-link' class='icon-header' title='Home' href=".. html.html_escape(pageinfo.wwwprefix) ..  "/cgi-bin/acf/acf-util/welcome/read".."><i class='fa-solid fa-house fa-2x home-icon'></i></a>")
					else
						print("<div id='header-links'><a id='logon' class='icon-header' title='Logon' href=\""..html.html_escape(ctlr).."logon\"><i class='fa-solid fa-lock fa-2x logon-icon'></i></a>" )
					end
				%>
				<a id="about-link" class="icon-header" href="https://gitlab.alpinelinux.org/trinity-labs/dashboard-skin" target="_blank" title="About"><i class="fa-regular fa-circle-question fa-2x about-icon"></i></i></a>
				<%
					if session.userinfo and session.userinfo.userid then
						print("<span id='text-user-logon' class='text-user-"..html.html_escape(session.userinfo.userid).."'>"..html.html_escape(session.userinfo.userid).." @ "..html.html_escape(hostname or "unknown hostname").."</span>")
						print("<span id='user-logon' class='user-"..html.html_escape(session.userinfo.userid).."'></span>")
					end
				%>
				</div>
</header>	<!-- header -->
			
			
<div id="nav" style="display: none;">
				<%
					local class
					local tabs
					if (#session.menu.cats > 0) then
						print("<ul>")
						for x,cat in ipairs(session.menu.cats) do
							cat.name = string.gsub(string.lower(cat.name), "%s+", "_")
							print("<!--ADD ITEM TITLE AND CATEGORY - 20231102-->")
							print("<li id='"..html.html_escape(cat.name).."-menu' class='category-menu'><h1 id='"..html.html_escape(cat.name).."-title' class='category-title'>"..html.html_escape(cat.name).."</h1>")
							print("<ul id='item-list'>")
							for y,group in ipairs(cat.groups) do
								class="class='item-field'"
								if not tabs and group.controllers[pageinfo.prefix .. pageinfo.controller] then
									class="class='selected item-field'"
									tabs = group.tabs
								end
								print("<li "..class.."><a "..class.." href=\""..html.html_escape(pageinfo.script)..html.html_escape(group.tabs[1].prefix)..html.html_escape(group.tabs[1].controller).."/"..html.html_escape(group.tabs[1].action).."\">"..html.html_escape(group.name).."</a></li>")
							end
							print("</ul>")
							print("</li>")
						end
						print("</ul>")
					end
				%>
</div>	<!-- nav -->
		<div id="page-<%= pageinfo.action %>" class="page page-<%= pageinfo.controller %>">
			<div id="main">
				<div id="subnav">
				<h1 class="page-header-title"><%= pageinfo.controller %></h1>
				<%
					local class=""
					if (tabs and #tabs > 0) then
						print("<ul>")
						for x,tab in pairs(tabs or {})  do
							if tab.prefix == pageinfo.prefix and tab.controller == pageinfo.controller and tab.action == pageinfo.action then
								class="class='selected'"
							else
								class=""
							end
							print("<li "..class.."><a "..class.." href=\""..html.html_escape(pageinfo.script)..html.html_escape(tab.prefix)..html.html_escape(tab.controller).."/"..html.html_escape(tab.action).."\">"..html.html_escape(tab.name).."</a></li>")
						end
						print("</ul>")
					end
				%>
				</div> <!-- subnav -->

				<div id="content">
<% end --pageinfo.skinned %>

					<% pageinfo.viewfunc(viewtable, viewlibrary, pageinfo, session) %>

<% if pageinfo.skinned ~= "false" then %>
				</div>	<!-- content -->

			</div> <!-- main -->

			<div id="footer" style="cursor: pointer;" onclick="window.open('https://www.alpinelinux.org/about/', '_blank')">
				<a href="https://www.alpinelinux.org/about/" target="_blank">
				© Alpine | 2008 - <%= html.html_escape(os.date("%Y")) %>
				</a>
			</div> <!-- footer -->
		</div> <!-- page -->
<% end --pageinfo.skinned%>
	</body>
</html>
