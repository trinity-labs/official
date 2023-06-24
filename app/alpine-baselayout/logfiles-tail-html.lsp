<% local form, viewlibrary, page_info, session = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>

<script type="text/javascript">
        if (typeof jQuery == 'undefined') {
                document.write('<script type="text/javascript" src="<%= html.html_escape(page_info.wwwprefix) %>/js/jquery-latest.js"><\/script>');
	}
</script>

<script type="text/javascript">
	var currentoffset = -1024
	var ID
	var started = false
	function Update(){
		$.ajaxSetup({cache:false});
		$.getJSON(
			'<%= html.html_escape(page_info.script .. page_info.prefix .. page_info.controller .. "/" .. page_info.action) %>',
			{filename:'<% io.write(html.html_escape(form.value.filename.value)) if form.value.grep.value ~= "" then io.write("',grep:'"..html.html_escape(form.value.grep.value)) end %>', offset:currentoffset, viewtype:'json'},
			function(data) {
				if (currentoffset != data.value.size.value){

					/* Before updating content, determine where we're scrolled to.  If we're within
					   25 pixels of the bottom, we'll stick to the bottom. */
					var content = $("#filecontent").get(0);
					var currentHeight = 0;
					var scrollTop = content.scrollTop;
					if (content.scrollHeight > 0)
						currentHeight = content.scrollHeight;
					else
						if (content.offsetHeight > 0)
							currentHeight = content.offsetHeight;
					if (currentHeight - scrollTop - ((content.style.pixelHeight) ? content.style.pixelHeight : content.offsetHeight) < 25)
						scrollTop = currentHeight;

					$("#filecontent").val($("#filecontent").val() + data.value.filecontent.value);

					/* Now, set the scroll. */
					if (scrollTop < currentHeight)
						content.scrollTop = scrollTop;
					else
						content.scrollTop = content.scrollHeight;

					currentoffset = data.value.size.value;
					$(".left:contains('File size')").next().text(currentoffset);
				};
				if (started) {
					ID=window.setTimeout("Update();", 1000);
				}
			}
		);
	}
	function handleerror(event, request, settings){
		$(this).append("Error requesting page " + settings.url + "<br/>Perhaps the session has timed out.");
		$("#Stop").click();
	};
	$(function(){
		$("#errtxt").ajaxError(handleerror);
		$("#Start").attr("disabled","disabled");
	   	<% if not form.value.filename.errtxt then %>
		started = true
	   	Update();
		<% else %>
		$("#Stop").attr("disabled","disabled");
		<% end %>
	});
</script>

<%
local header_level = htmlviewfunctions.displaysectionstart(form, page_info)
htmlviewfunctions.displayitem(form.value.filename)
htmlviewfunctions.displayitem(form.value.size)
if form.value.grep.value ~= "" then
	htmlviewfunctions.displayitem(form.value.grep)
end
%>
<textarea id="filecontent">
</textarea>
<p class="error" id="errtxt"></p>
<% htmlviewfunctions.displayitemstart() %>
Start / Stop tailing file
<% htmlviewfunctions.displayitemmiddle() %>
<input type="button" id="Start" value="Start" onClick='$("#errtxt").empty(); started=true; Update(); $("#Start").attr("disabled","disabled");$("#Stop").removeAttr("disabled");'>
<input type="button" id="Stop" value="Stop" onClick='started=false; window.clearTimeout(ID); $("#Stop").attr("disabled","disabled");$("#Start").removeAttr("disabled");'>
<% htmlviewfunctions.displayitemend() %>
<% htmlviewfunctions.displaysectionend(header_level) %>
