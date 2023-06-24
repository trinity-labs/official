<% local form, viewlibrary, page_info, session = ...
htmlviewfunctions = require("htmlviewfunctions")
html = require("acf.html")
json = require("json")

-- iface is a local table with cfes for the various parts of interface definitions
-- Depending on the address family and corresponding method, different options are valid
local iface = require("alpine-baselayout/interfaces-definitions")
for name,value in pairs(iface.optional) do
	form.value[name].class = "optional"
end
%>

<script type="text/javascript">
	if (typeof jQuery == 'undefined') {
		document.write('<script type="text/javascript" src="<%= html.html_escape(page_info.wwwprefix) %>/js/jquery-latest.js"><\/script>');
	}
</script>

<script type="text/javascript">
	var methodoptions = <%= json.encode(iface.method_options) %>;

	var familymethods = <%= json.encode(iface.family_methods) %>;

	function showoptionalfields() {
		var family = $("select[name='family']").val();
		var method = $("select[name='method']").val();
		var optionalarray = [];
		if (methodoptions[family] && methodoptions[family][method])
			optionalarray = methodoptions[family][method];

		// show / hide all of the optional inputs
		$(".optional").each(function() {
			if (jQuery.inArray($(this).attr('name'), optionalarray)==-1) {
				$(this).parents(".item").hide();
			} else {
				$(this).parents(".item").show();
			}
		});
	}
	function methodchange() {
		$(this).removeClass('error').siblings().remove();
		$(this).parent().prev().removeClass('error');
		$(this).find("option").remove("*:contains('[')");
		showoptionalfields();
	}
	function familychange() {
		$(this).removeClass('error').siblings().remove();
		$(this).parent().prev().removeClass('error');
		$(this).find("option").remove("*:contains('[')");
		var method = $("select[name='method']");
		method.find("option").remove();	// this also ensures that nothing is selected
		if (familymethods[$(this).val()]) {
			jQuery.each(familymethods[$(this).val()], function(index, value) {
				method.append('<option selected value="'+value+'">'+value+'</option>');
			});
		}
		method.append('<option selected value="">[]</option>');
		$(".optional").parents(".item").hide();
	}
	$(function(){
		$("select[name='family']").change(familychange);
		$("select[name='method']").change(methodchange);
		// Remove the method options that aren't valid for this family
		var familyval = $("select[name='family']").val();
		var method = $("select[name='method']");
		if (familymethods[familyval]) {
			method.find("option").each(function() {
				if (jQuery.inArray($(this).val(), familymethods[familyval])==-1)
					$(this).remove();
			});
		} else {
			method.find("option").remove();
			method.append('<option selected value="">[]</option>');
		}
		showoptionalfields();
	});
</script>

<%
if page_info.action == "update" then form.label = form.label.." - "..form.value.name.value end
htmlviewfunctions.displayitem(form, page_info)
%>
