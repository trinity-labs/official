// GLOBAL JS FUNCTIONS
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
// Security Inactivity Logoff (5 minutes)
    if (window.location.href.indexOf("logon") === -1) {  // Check if user is not logon page
        function inactivity() {
            let time;
            let warningTimer;
			let warningToast;

            // Events list
            const events = [
                'load', 'mousemove', 'mousedown', 'touchstart', 
                'click', 'keydown', 'scroll'
            ];

            events.forEach(event => document.addEventListener(event, resetTimer, true));

            // Back to logon
            function logout() {
                window.location.href = '//' + window.location.hostname + '/cgi-bin/acf/acf-util/logon/logoff';
            }

            // Show warn
            function showWarning() {
                warningToast = document.createElement('div');
                warningToast.innerHTML = "⚠️ &nbsp;&nbsp;Log out in 5 minutes due to your inactivity!";
                warningToast.style.position = "fixed";
                warningToast.style.fontFamily = "system-ui, 'Font Awesome 6 Free'";
                warningToast.style.fontWeight = "600";
                warningToast.style.fontSize = "1rem";            
                warningToast.style.top = "4rem";
                warningToast.style.left = "50%";
                warningToast.style.padding = "0.75rem 2rem";
                warningToast.style.backgroundColor = "rgb(255 165 0 / 86%)";
                warningToast.style.color = "black";
                warningToast.style.borderRadius = "4px";
                warningToast.style.transform = "translateX(-50%)"; // Centrer horizontalement
                document.body.appendChild(warningToast);
            }
			// Reset
            function resetTimer() {
                clearTimeout(time);
                clearTimeout(warningTimer);
				if (warningToast) {
                    warningToast.remove();
                    warningToast = null;  // Reset Toast
                }
                warningTimer = setTimeout(showWarning, 300000); // 5 minutes = 300 000 millisecondes
                time = setTimeout(logout, 600000);  // 10 minutes = 600 000 millisecondes
            }
            resetTimer();
        }
        inactivity();
    }
// Add tablesorter-ice class to .tablesorter objects
			$(".tablesorter").addClass("tablesorter-ice");
// Login page input placeholder
			if(window.location.href.indexOf("logon/logon") > -1){
				document.querySelector('#userid input').setAttribute('required','required');
				document.querySelector('#password input').setAttribute('required','required');
				document.querySelector('#userid input').setAttribute('style',"font-family: system-ui, 'Font Awesome 6 Free'; font-weight: 600");
				document.querySelector('#userid input').setAttribute('placeholder','    User ID');
				document.querySelector('#password input').setAttribute('style',"font-family: system-ui, 'Font Awesome 6 Free'; font-weight: 600");
				document.querySelector('#password input').setAttribute('placeholder','    Password');
				document.querySelector('#login').setAttribute('autocomplete','on');
				document.querySelector('#password input').setAttribute('autocomplete','current-password');
				document.querySelector('.hidden').setAttribute('hidden','');
				$("#password .right").append("<button id='showPass' type='button' onclick='showPassword()'><i class='fa-regular fa-eye-slash'></i></button>"); 
			};
// Save Menu state 
			var menuUpdated = window.localStorage.getItem('nav', menuUpdated);	
			if (window.localStorage.getItem('nav') === 'active') {
				$("#nav").css({display: 'block'});
				$("#content").css({width: '80%'});
				$("#subnav").css({width: '80%'});
			} else {
				$("#content").css({width: '100%'});
				$("#subnav").css({width: '100%'});
			};
			if (menuUpdated === null) {
				window.localStorage.setItem('nav', 'active');
				$("#nav").toggleClass("active");
				$("#toggle").toggleClass("active");
			} else {
				window.localStorage.getItem('nav', menuUpdated);
				$("#nav").toggleClass(menuUpdated);
				$("#toggle").toggleClass(menuUpdated);
			}
// Save Theme state			
			var themeUpdated = window.localStorage.getItem('html', themeUpdated);	
			if (window.localStorage.getItem('html') === 'light-theme') {
				$("#html").toggleClass("light-theme");
				$("#theme-toggle").prop( "checked", false );
			} else {
				$("#html").toggleClass("dark-theme");
				$("#theme-toggle").prop( "checked", true );
			};
			if (themeUpdated === null) {
				window.localStorage.setItem('html', 'light-theme');
				$("#html").toggleClass("light-theme");
				$("#theme-toggle").prop( "checked", false );
			} else {
				window.localStorage.getItem('html', themeUpdated);
				$("html").toggleClass(themeUpdated);
			}
			
// Save Degree state
			var degreeUpdated = window.localStorage.getItem('toggle-degree', degreeUpdated);	
			if (window.localStorage.getItem('toggle-degree') === 'celsius') {
				$("#toggle-degree").prop( "checked", false );
				$("#temp-cap-normal").html("50°<sup>C</sup>");
				$("#temp-cap-medium").html("50°<sup>C</sup>");
				$("#temp-cap-hot").html("75°<sup>C</sup>");
			} else {
				$("#toggle-degree").prop( "checked", true );
				$("#temp-cap-normal").html("122°<sup>F</sup>");
				$("#temp-cap-medium").html("122°<sup>F</sup>");
				$("#temp-cap-hot").html("167°<sup>F</sup>");
			};
			if (degreeUpdated === null) {
				window.localStorage.setItem('toggle-degree', 'celsius');
				$("#toggle-degree").prop( "checked", false );
			} else {
				window.localStorage.getItem('toggle-degree', degreeUpdated);
			}
		});
// Toggle collapse menu
			function toggleMenu() {  
			var menuUpdated = window.localStorage.getItem('nav', menuUpdated);
				$("#nav").toggleClass("active");
				$("#toggle").toggleClass("active");
			if (window.localStorage.getItem('nav') === 'active') {
				menuUpdated = 'not_active';
				$("#nav").css({display: 'none'});
				$("#content").animate({width: '100%'});
				$("#subnav").animate({width: '100%'});
				$("#nav").toggleClass("not_active");
				$("#toggle").toggleClass("not_active");
			} else {
				menuUpdated = 'active';
				$("#nav").slideToggle(900);
				$("#nav").removeClass("not_active");
				$("#content").animate({width: '80%'});
				$("#subnav").animate({width: '80%'});
				$("#nav").css({display: 'block'});
				$("#toggle").removeClass("not_active");	
			}
			window.localStorage.setItem('nav', menuUpdated);
			};		
// Toogle degree °C <=> F°
			function toggleDegree() { 
			var degreeUpdated = window.localStorage.getItem('toggle-degree', degreeUpdated);
			if (window.localStorage.getItem('toggle-degree') === 'celsius') {
				degreeUpdated = 'fahrenheit';
				$("#temp-cap-normal").html("122°<sup>F</sup>");
				$("#temp-cap-medium").html("122°<sup>F</sup>");
				$("#temp-cap-hot").html("167°<sup>F</sup>");
			} else {
				degreeUpdated = 'celsius';
				$("#temp-cap-normal").html("50°<sup>C</sup>");
				$("#temp-cap-medium").html("50°<sup>C</sup>");
				$("#temp-cap-hot").html("75°<sup>C</sup>");
			}
			window.localStorage.setItem('toggle-degree', degreeUpdated);
			};
// Toogle Dark Theme			
			function toggleTheme() {
			var themeUpdated = window.localStorage.getItem('html', themeUpdated);
			$("#html").toggleClass("light-theme");
			if (window.localStorage.getItem('html') === 'light-theme') {
				themeUpdated = 'dark-theme';
				$("html").toggleClass("dark-theme");
				$("html").removeClass("light-theme");
			} else {
				themeUpdated = 'light-theme';
				$("html").toggleClass("light-theme");
				$("html").removeClass("dark-theme");
			}
			window.localStorage.setItem('html', themeUpdated);
			};	
// ChartJS API		
			if(window.location.href.indexOf("/acf/acf-util/welcome/read") > -1){			
			async function api() {
				let url = document.location.hostname + '/alpine-baselayout/health/api?viewtype=json';
				let obj = await (await fetch(url)).json();				
// FORMATED TEMP JS LIVE TIMER
				if (((obj.value.cpuTemp.value) < 50000) && (window.localStorage.getItem('toggle-degree') === 'celsius')) {
					document.getElementById("cpuTemp").innerHTML = (Math.ceil((obj.value.boardTemp.value) / 1000)) + (" °C  &nbsp; | <span class='normal'>" + (obj.value.cpuTemp.value) / 1000) + " °C</span>";
				} else if (((obj.value.cpuTemp.value) >= 50000) && (window.localStorage.getItem('toggle-degree') === 'celsius')) {
					document.getElementById("cpuTemp").innerHTML = (Math.ceil((obj.value.boardTemp.value) / 1000)) + (" °C  &nbsp; | <span class='medium'>" + (obj.value.cpuTemp.value) / 1000) + " °C</span>";
				} else if (((obj.value.cpuTemp.value) >= 75000) && (window.localStorage.getItem('toggle-degree') === 'celsius')) {
					document.getElementById("cpuTemp").innerHTML = (Math.ceil((obj.value.boardTemp.value) / 1000)) + (" °C  &nbsp; | <span class='hot'>" + (obj.value.cpuTemp.value) / 1000) + " °C</span>";
// FORMATED TEMP TO FAHRENHEIT
				} else if (((obj.value.cpuTemp.value) < 50000) && (window.localStorage.getItem('toggle-degree') === 'fahrenheit')) {
					document.getElementById("cpuTemp").innerHTML = (Math.ceil((((obj.value.boardTemp.value) / 1000) * 9 / 5) + 32)) + (" °F  &nbsp; | <span class='normal'>" + (Math.floor(((obj.value.cpuTemp.value) / 1000) * 9 / 5) + 32)) + " °F</span>";
				} else if (((obj.value.cpuTemp.value) >= 50000) && (window.localStorage.getItem('toggle-degree') === 'fahrenheit')) {
					document.getElementById("cpuTemp").innerHTML = (Math.ceil((((obj.value.boardTemp.value) / 1000) * 9 / 5) + 32)) + (" °F  &nbsp; | <span class='medium'>" + (Math.floor(((obj.value.cpuTemp.value) / 1000) * 9 / 5) + 32)) + " °F</span>";
				} else if (((obj.value.cpuTemp.value) >= 75000) && (window.localStorage.getItem('toggle-degree') === 'fahrenheit')) {
					document.getElementById("cpuTemp").innerHTML = (Math.ceil((((obj.value.boardTemp.value) / 1000) * 9 / 5) + 32)) + (" °F  &nbsp; | <span class='hot'>" + (Math.floor(((obj.value.cpuTemp.value) / 1000) * 9 / 5) + 32)) + " °F</span>";					
				} else {
					document.getElementById("cpuTemp").innerHTML = ((obj.value.boardTemp.value) / 1000) + (" °C  &nbsp; | <span class='nan'>N/A</span>");
				};
				window.localStorage.removeItem('CTemp');
				window.localStorage.setItem('CTemp', (Math.floor((obj.value.cpuTemp.value)) / 1000));
				window.localStorage.removeItem('MemoryUse');
				window.localStorage.setItem('MemoryUse', (obj.value.memUsed));
				window.localStorage.removeItem('MemoryTotal');
				window.localStorage.setItem('MemoryTotal', (obj.value.memTotal));
			};
			// Build Chart	
			$(function chartCpuTemp() {
			// Setup Block
				const data = {
				  labels: [],
				  datasets: [{
					label: 'CPU Temp',
					borderColor : 'rgba(255, 105, 180)',
					backgroundColor: 'rgba(255, 105, 180, 0.5)',
					color: 'rgba(0, 179, 162)',
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
							frameRate: 1
				  },
					  scales: {
						x: {
							type: 'realtime',
							realtime: {
								duration: 30000,
								refresh: 1000,
								delay: 0,
								onRefresh: chart => {
									chart.data.datasets.forEach(dataset => {
										dataset.data.push({
										x: Date.now(),
										y: localStorage.getItem("CTemp")
										})
									})
								}
							}
						},
						y: {
							suggestedMin: (Number(localStorage.getItem("CTemp")) - 1),
							suggestedMax: (Number(localStorage.getItem("CTemp")) + 1),
						ticks: {
							stepSize: 1,
							stepValue: 10
						}}
					  },
					   plugins: {
							legend: false
						}
					}
				  };
			// Render Block
				const chartCpuTemp = new Chart(
					document.getElementById('chartCpuTemp'),
					config
				);
			});
			
			$(function chartMemUsed() {
			// Setup Block
				const data = {
				  labels: [],
				  datasets: [{
					label: 'Memory Usage',
					borderColor : 'rgba(255, 120, 0)',
					backgroundColor: 'rgba(255, 120, 0, 0.5)',
					color: 'rgba(0, 179, 162)',
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
							frameRate: 1
				  },
					  scales: {
						x: {
							type: 'realtime',
							realtime: {
								duration: 30000,
								refresh: 1000,
								delay: 0,
								onRefresh: chart => {
									chart.data.datasets.forEach(dataset => {
										dataset.data.push({
										x: Date.now(),
										y: localStorage.getItem("MemoryUse")
										})
									})
								}
							}
						},
						y: {
							suggestedMin: 0,
							suggestedMax: Math.floor(Number(localStorage.getItem("MemoryTotal"))),
						ticks: {
							stepSize: 4,
							stepValue: 10
						}}
					  },
					 plugins: {
							legend: false
						}
					}
				  };
			// Render Block
				const  chartMemUsed = new Chart(
					document.getElementById('chartMemUsed'),
					config
				);
			});
refresh = setInterval(api, 1000);
};