// GLOBAL JS FUNCTIONS
$(function() {
	$(":input:not(input[type=button],input[type=submit],button):enabled:not([readonly]):visible:first").focus();
// Add tablesorter-ice class to .tablesorter objects
	$(".tablesorter").addClass("tablesorter-ice");
	});			
// Toggle functions
function toggleMenu() {
    const isActive = $("#nav").hasClass("active");
    $("#nav, #toggle, #toggle-menu").toggleClass("active not_active"); 
    if (isActive) {
        $("#nav").hide();
        $("#content, #subnav").css("width", "100%");
    } else {
        $("#nav").slideDown(900);
        $("#content, #subnav").css("width", "85%");
    }
    window.localStorage.setItem('nav', isActive ? 'not_active' : 'active');
}
function toggleDegree() {
    const isCelsius = window.localStorage.getItem('toggle-degree') === 'celsius';
    const temps = isCelsius ? ["122°<sup>F</sup>", "167°<sup>F</sup>"] : ["50°<sup>C</sup>", "75°<sup>C</sup>"];
    $("#temp-cap-normal, #temp-cap-medium").html(temps[0]);
    $("#temp-cap-hot").html(temps[1]);
    window.localStorage.setItem('toggle-degree', isCelsius ? 'fahrenheit' : 'celsius');
}
function toggleTheme() {
    const isDarkTheme = $("html").toggleClass("dark-theme light-theme").hasClass("dark-theme");
    window.localStorage.setItem('html', isDarkTheme ? 'dark-theme' : 'light-theme');
}
// Show Password Toggle Functionality
	if (location.href.includes("logon/logon")) {
		const setAttrs = (el, ph) => el.attr({
		required: true,
		placeholder: ph,
		style: "font-family: system-ui, 'Bootstrap-icons', 'Font Awesome 6 Free', 'Material Icons Outlined'; font-variation-settings: 'OPSZ' 48 !important;"

		});
		setAttrs($('#userid input'), '\uf007    User ID');
		setAttrs($('#password input'), '\ue897    Password').attr('autocomplete', 'current-password');
		$('#login').attr('autocomplete', 'on');
		$('.hidden').attr('hidden', true);
		$("#password .right").append("<button id='showPass' type='button'><i class='fa-regular fa-eye-slash'></i></button>");
		$("#showPass").on('click', function() {
		const field = $('#password input');
		const isPassword = field.attr('type') === 'password';
		field.attr('type', isPassword ? 'text' : 'password');
		$(this).toggleClass('corporate');
		$("#showPass i").toggleClass('fa-eye fa-eye-slash');
	})};		
//Wait DOM
$(document).ready(function() {	
// Inactivity Logoff & Warning
$(function() {
    if (!window.location.href.includes("logon")) {
        let logoutTimer, warningTimer;
        const events = 'load mousemove mousedown touchstart click keydown scroll';
        function resetTimer() {
            clearTimeout(logoutTimer);
            clearTimeout(warningTimer);
            $('#warningToast').remove();
            warningTimer = setTimeout(showWarning, 300000); // 5 minutes
            logoutTimer = setTimeout(logout, 600000);  // 10 minutes
        }
        function logout() {
            window.location.href = `//${window.location.hostname}/cgi-bin/acf/acf-util/logon/logoff`;
        }
        function showWarning() {
            $('body').append(`<div id="warningToast">⚠️ &nbsp;&nbsp;Log out in 5 minutes due to your inactivity!</div>`);
        }
        $(document).on(events, resetTimer);
        resetTimer();
    }
});
// Full Size Disk-Listing for Odd Position
$(function() {
    let diskListings = document.querySelectorAll('#disk-listing');
    if (diskListings.length % 2 !== 0) {
        diskListings[diskListings.length - 1].style.width = "98%";
    }
});
// Assign Toggles
$(function() {
    function setClassAndProp(selector, className, prop, value) {
		$(selector).toggleClass(className);
		if (prop !== null) $(selector).prop(prop, value);
    }
    let menuState = window.localStorage.getItem('nav') || 'active';
    setClassAndProp("#nav", menuState, null, null);
    setClassAndProp("#toggle-menu", menuState, null, null);
    const menuWidth = menuState === 'active' ? '85%' : '100%';
    $("#nav").css('display', menuState === 'active' ? 'block' : 'none');
    $("#content, #subnav").css('width', menuWidth);
    let themeState = window.localStorage.getItem('html') || 'dark-theme';
    $("html").toggleClass(themeState);
    const isDarkTheme = themeState === 'light-theme';
    $("#toggle-theme").prop("checked", !isDarkTheme);
    let degreeState = window.localStorage.getItem('toggle-degree') || 'celsius';
    const isCelsius = degreeState === 'celsius';
    $("#toggle-degree").prop("checked", !isCelsius);
    const degreeLabels = isCelsius ? ["50°<sup>C</sup>", "75°<sup>C</sup>"] : ["122°<sup>F</sup>", "167°<sup>F</sup>"];
    $("#temp-cap-normal, #temp-cap-medium").html(degreeLabels[0]);
    $("#temp-cap-hot").html(degreeLabels[1]);
    // Save states if not set initially
    if (!window.localStorage.getItem('nav')) {
        window.localStorage.setItem('nav', menuState);
    }
    if (!window.localStorage.getItem('html')) {
        window.localStorage.setItem('html', themeState);
    }
    if (!window.localStorage.getItem('toggle-degree')) {
        window.localStorage.setItem('toggle-degree', degreeState);
    }
});
// ChartJS API
if (window.location.href.indexOf("/acf/acf-util/welcome/read") > -1) {			
	$(function() {
		async function api() {
			const url = `${document.location.hostname}/alpine-baselayout/health/api?viewtype=json`;
			const obj = await (await fetch(url)).json();
			const $cpuTemp = $("#cpuTemp");
			const toggleDegree = localStorage.getItem('toggle-degree');
			const boardTempC = Math.ceil(obj.value.boardTemp.value / 1000);
			const cpuTempC = Math.floor(obj.value.cpuTemp.value / 1000);
			const tempClass = cpuTempC < 50 ? 'normal' : cpuTempC >= 75 ? 'hot' : 'medium';
			const boardTemp = toggleDegree === 'fahrenheit' ? Math.ceil(boardTempC * 9 / 5 + 32) : boardTempC;
			const cpuTemp = toggleDegree === 'fahrenheit' ? Math.floor(cpuTempC * 9 / 5 + 32) : cpuTempC;
			const unit = toggleDegree === 'fahrenheit' ? '°F' : '°C';
			$cpuTemp.html(`${boardTemp} ${unit}  &nbsp; <span class='hdivider'>|</span> <span class='${tempClass}'>${cpuTemp} ${unit}</span>`);
			
			// Store values
			localStorage.setItem('CTemp', cpuTempC);
			localStorage.setItem('MemoryUse', obj.value.memUsed);
			localStorage.setItem('MemoryTotal', obj.value.memTotal);

			// Extract CPU frequencies
			const cpuText = obj.value.cpu.value;
			const cpuFrequencies = [];
			const cpuLines = cpuText.split("\n");

			// Get "cpu MHz" values
			cpuLines.forEach(line => {
				if (line.includes("cpu MHz")) {
					const frequency = parseFloat(line.split(":")[1].trim());
					cpuFrequencies.push(frequency);
				}
			});
			
			// Calculate average CPU frequency
			if (cpuFrequencies.length > 0) {
				const avgCpuFreq = cpuFrequencies.reduce((a, b) => a + b, 0) / cpuFrequencies.length;
				localStorage.setItem('CPUFreq', avgCpuFreq);
			} else {
				console.error("Unable to extract CPU frequencies.");
			}
		}

		// Create chart with units in Y axis and temperature conversion
		function createChart(elementId, label, borderColor, backgroundColor, dataKey, yMinDelta, yMax, yStepSize, yUnit) {
			const data = {
				labels: [],
				datasets: [{
					label: label,
					borderColor: borderColor,
					backgroundColor: backgroundColor,
					data: [],
					tension: 0,
					fill: true,
					pointRadius: 0
				}],
			};
			const config = {
				type: 'line',
				data,
				options: {
					scales: {
						x: {
							type: 'realtime',
							realtime: {
								duration: 30000,
								refresh: 1000,
								delay: 0,
								onRefresh: chart => {
									let newValue = Number(localStorage.getItem(dataKey));
									
									// Convert CPU Temp to °F if toggle-degree is set to 'fahrenheit'
									const toggleDegree = localStorage.getItem('toggle-degree');
									if (dataKey === 'CTemp' && toggleDegree === 'fahrenheit') {
										newValue = newValue * 9 / 5 + 32;
									}

									chart.data.datasets.forEach(dataset => {
										dataset.data.push({
											x: Date.now(),
											y: newValue
										});
									});
									
									if (dataKey === 'CTemp' || dataKey === 'CPUFreq') {
										chart.options.scales.y.suggestedMin = newValue - yMinDelta;
										chart.options.scales.y.suggestedMax = newValue + yMinDelta;
									}
								}
							}
						},
						y: {
							suggestedMin: 0,
							suggestedMax: yMax,
							ticks: {
								stepSize: yStepSize,
								callback: function(value) {
									if (dataKey === 'CTemp') {
										// Display °F if toggle-degree is set, else °C
										const toggleDegree = localStorage.getItem('toggle-degree');
										return toggleDegree === 'fahrenheit' ? value + ' °F' : value + ' °C';
									} else if (dataKey === 'CPUFreq') {
										// Convert MHz to GHz if above 1000 MHz
										return value >= 1000 ? (value / 1000).toFixed(2) + ' GHz' : value + ' MHz';
									}
									return value;
								}
							}
						}
					},
					plugins: {
						legend: {
							display: false
						}
					}
				}
			};
			new Chart(document.getElementById(elementId), config);
		}

		// Create charts
		createChart(
			'chartCpuTemp',
			'CPU Temp',
			'rgba(255, 105, 180)',
			'rgba(255, 105, 180, 0.5)',
			'CTemp',
			1,
			null,
			1,
			'°C' // Will change dynamically based on toggle-degree
		);

		const memoryTotal = Math.floor(Number(localStorage.getItem('MemoryTotal')));
		const memoryStepSize = Math.max(1, Math.ceil(memoryTotal / 4));
		createChart(
			'chartMemUsed',
			'Memory Usage',
			'rgba(255, 120, 0)',
			'rgba(255, 120, 0, 0.5)',
			'MemoryUse',
			0,
			memoryTotal,
			memoryStepSize
		);

		createChart(
			'chartCpuFreq',
			'CPU Frequency',
			'rgba(141, 114, 207)',
			'rgba(141, 114, 207, 0.5)',
			'CPUFreq',
			100,
			5000,
			500,
			'GHz'
		);

		// Update every second
		setInterval(api, 1000);
		});
	};
});