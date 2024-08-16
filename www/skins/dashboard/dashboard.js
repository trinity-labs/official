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
        $("#content, #subnav").css("width", "80%");
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
    const isLightTheme = $("html").toggleClass("light-theme dark-theme").hasClass("light-theme");
    window.localStorage.setItem('html', isLightTheme ? 'light-theme' : 'dark-theme');
}
// Show Password Toggle Functionality
	if (location.href.includes("logon/logon")) {
		const setAttrs = (el, ph) => el.attr({
		required: true,
		placeholder: ph,
		style: "font-family: system-ui, 'Font Awesome 6 Free'; font-weight: 600"
		});
		setAttrs($('#userid input'), '\uf007    User ID');
		setAttrs($('#password input'), '\uf023    Password').attr('autocomplete', 'current-password');
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
// Assign Toggles
$(function() {
    function setClassAndProp(selector, className, prop, value) {
		$(selector).toggleClass(className);
		if (prop !== null) $(selector).prop(prop, value);
    }
    let menuState = window.localStorage.getItem('nav') || 'active';
    setClassAndProp("#nav", menuState, null, null);
    setClassAndProp("#toggle-menu", menuState, null, null);
    const menuWidth = menuState === 'active' ? '80%' : '100%';
    $("#nav").css('display', menuState === 'active' ? 'block' : 'none');
    $("#content, #subnav").css('width', menuWidth);
    let themeState = window.localStorage.getItem('html') || 'light-theme';
    $("html").toggleClass(themeState);
    const isLightTheme = themeState === 'light-theme';
    $("#toggle-theme").prop("checked", !isLightTheme);
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
	if(window.location.href.indexOf("/acf/acf-util/welcome/read") > -1){			
	$(function() {async function api() {
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
		$cpuTemp.html(`${boardTemp} ${unit}  &nbsp; | <span class='${tempClass}'>${cpuTemp} ${unit}</span>`);
		localStorage.setItem('CTemp', cpuTempC);
		localStorage.setItem('MemoryUse', obj.value.memUsed);
		localStorage.setItem('MemoryTotal', obj.value.memTotal);
	}
// Common chart setup
  function createChart(elementId, label, borderColor, backgroundColor, dataKey, yMinDelta, yMax, yStepSize) {
    const data = {
    labels: [],
    datasets: [{
	label: label,
	borderColor: borderColor,
	backgroundColor: backgroundColor,
	data: [],
	tension: 0.25,
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
                const newValue = Number(localStorage.getItem(dataKey));
                chart.data.datasets.forEach(dataset => {
                  dataset.data.push({
                    x: Date.now(),
                    y: newValue
                  });
                });
                // For CPU, adjust suggested min/max based on current value
                if (dataKey === 'CTemp') {
                  chart.options.scales.y.suggestedMin = newValue - yMinDelta;
                  chart.options.scales.y.suggestedMax = newValue + yMinDelta;
                }
              }
            }
          },
          y: {
            suggestedMin: 0,
            suggestedMax: yMax, // Correctly setting suggested max for memory
            ticks: {
              stepSize: yStepSize // Ensure this is set appropriately
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
  // Create CPU Temperature Chart
  createChart(
    'chartCpuTemp',
    'CPU Temp',
    'rgba(255, 105, 180)',
    'rgba(255, 105, 180, 0.5)',
    'CTemp',
    1,  // Min delta for CPU temperature
    null, // CPU chart does not use a fixed max
    1   // Step Size
  );

  // Create Memory Usage Chart
  const memoryTotal = Math.floor(Number(localStorage.getItem('MemoryTotal')));
  const memoryStepSize = Math.max(1, Math.ceil(memoryTotal / 4)); // Ensure at least 1 and is an integer
  createChart(
    'chartMemUsed',
    'Memory Usage',
    'rgba(255, 120, 0)',
    'rgba(255, 120, 0, 0.5)',
    'MemoryUse',
    0,  // Min delta (not used for memory)
    memoryTotal, // Use memory total from localStorage
    memoryStepSize // Integer Step Size
  );
refresh = setInterval(api, 1000);
		});
	};
});