<% view, viewlibrary, page_info = ... %>
<% htmlviewfunctions = require("htmlviewfunctions") %>
<% html = require("acf.html") %>

<style type="text/css">
	p.hiddendetail {
		display: none;
	}
	p.error a{
		display: block;
		font-weight: normal;
		font-size: 75%;
	}
</style>
<script type="text/javascript">
        if (typeof jQuery == 'undefined') {
                document.write('<script type="text/javascript" src="<%= html.html_escape(page_info.wwwprefix) %>/js/jquery-latest.js"><\/script>');
	}
</script>

<script type="text/javascript">
	var clickIt = function(){
			$("p.hiddendetail").removeClass("hiddendetail").show("slow");
			$(this).fadeOut("slow");
	};
	$(document).ready(function(){
		$("p.errordetail").append('<a href="javascript:;">Show Detail</a>').find("a").click(clickIt);
		$("p.errordetail").addClass("error");
	});
</script>

<% local header_level = htmlviewfunctions.displaysectionstart(cfe({label="Alpine Configuration Framework"}), page_info) %>
<p class="errordetail">Dispatch error occured</p>
<p class="hiddendetail">'<%= html.html_escape(view.controller) %>' does not have a '<%= html.html_escape(view.action) %>' action.</p>
<% htmlviewfunctions.displaysectionend(header_level) %>
