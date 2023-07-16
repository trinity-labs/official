// GLOBAL FUNCTIONS

		$(function(){
				$(":input:not(input[type=button],input[type=submit],button):enabled:not([readonly]):visible:first").focus();
			});
			

// Show Password on Logon page
			function showPassword() {
				var field = document.querySelector('#password input');
				if (field.type === "password") {
					field.type = "text";
					$("#showPass .fa-eye-slash").removeClass("fa-eye-slash");
					$("#showPass i").addClass("fa-eye");
					$("#showPass").addClass("corporate");
				} else {
					field.type = "password";
					$("#showPass").removeClass("corporate");
					$("#showPass .fa-eye").removeClass("fa-eye");
					$("#showPass i").addClass("fa-eye-slash");
				}
				};			
// Wait page loading
			$(document).ready(function() {
// Add tablesorter-ice class to .tablesorter objects
// Note: you must load jquery before loading this file
					$(".tablesorter").addClass("tablesorter-ice");
// Login page input placeholder
				if(window.location.href.indexOf("logon/logon") > -1){
					document.querySelector('#userid input').setAttribute('required','required');
					document.querySelector('#password input').setAttribute('required','required');
					document.querySelector('#userid input').setAttribute('placeholder','🔒 User ID');
					document.querySelector('#password input').setAttribute('placeholder','🔑 Password');
					document.querySelector('#login').setAttribute('autocomplete','on');
					document.querySelector('#password input').setAttribute('autocomplete','current-password');
					document.querySelector('.hidden').setAttribute('hidden','');
					$("#password .right").append("<button id='showPass' type='button' onclick='showPassword()'><i class='fa-regular fa-eye-slash'></i></button>"); 
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
				$("#toggle").toggleClass("active");
			} else {
				window.localStorage.getItem('nav', updated);
				$("#nav").toggleClass(updated);
				$("#toggle").toggleClass(updated);
			}
// Save degree conversion state 
			var updated = window.localStorage.getItem('toogle-degree', updated);	
			if (window.localStorage.getItem('toogle-degree') === 'celsius') {
				updated = 'fahrenheit';
				$("#toggle-degree").toggleClass("fahrenheit");
			} else {
				updated = 'celsius';
				$("#toggle-degree").toggleClass("celsius");
			};
			});
// Toogle collapse menu
			function toggleMenu() {  
				var updated = window.localStorage.getItem('nav', updated);
				$("#nav").toggleClass("active");
				$("#toggle").toggleClass("active");
			if (window.localStorage.getItem('nav') === 'active') {
				updated = 'not_active';
				nav.style.display = "none";
				$("#content").animate({width: '100%'});
				$("#subnav").animate({width: '100%'});
				$("#nav").toggleClass("not_active");
				$("#toggle").toggleClass("not_active");
			} else {
				updated = 'active';
				$("#nav").slideToggle(900);
				$("#nav").removeClass("not_active");
				$("#toggle").removeClass("not_active");
				nav.style.display = "block";
				$("#content").animate({width: '80%'});
				$("#subnav").animate({width: '80%'});
				
			}
			window.localStorage.setItem('nav', updated);
			};		
// Toogle degree °C <=> F°
			function toggleDegree() { 
			var updated = window.localStorage.getItem('toggle-degree', updated);
			if (window.localStorage.getItem('toggle-degree') === 'celsius') {
				updated = 'fahrenheit';
				$("#toggle-degree").toggleClass("fahrenheit");
				$("#toggle-degree").removeClass("celsius");
			} else {
				updated = 'celsius';
				$("#toggle-degree").toggleClass("celsius");
				$("#toggle-degree").removeClass("fahrenheit");
			}
		
			window.localStorage.setItem('toggle-degree', updated);

			};						
// IMPORT UPTIME FOR JS LIVE TIMER
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
	// FORMAT JS UPTIME UP TO CENTURIES 😂
		var centuries_display = js_centuries > 0 ? js_centuries + (js_centuries <= 1 ? " Century " : " Centuries ") : "";
		var years_display = js_years > 0 ? js_years + (js_years <= 1 ? " Year " : " Years ") : "";
		var mounths_display = js_mounths > 0 ? js_mounths + (js_mounths <= 1 ? " Mounth " : " Mounths ") : "";
		var days_display = js_days > 0 ? js_days + (js_days <= 1 ? " Day " : " Days ") : "";
		var hours_display = js_hours < 10 ? "0" + js_hours + "h " : js_hours + "h ";
		var minutes_display = js_minutes < 10 ? "0" + js_minutes + "m " : js_minutes + "m ";
		var secondes_display = js_seconds < 10 ? "0" + js_seconds + "s" : js_seconds + "s";
	// RETURN JS FORMAT TIME
		return centuries_display + years_display + mounths_display + days_display + hours_display + minutes_display + secondes_display;	
	};
	// PUSH JS FORMAT TIME
	setInterval(() => document.getElementById("uptime").innerHTML = delay(), 1000);
			