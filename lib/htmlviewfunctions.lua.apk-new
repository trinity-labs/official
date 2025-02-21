local mymodule = {}

html = require("acf.html")
session = require("session")

local function searchoption(option, value)
	for x,val in ipairs(option) do
		local v,l
		if type(val) == "string" then
			v = val
			l = val
		elseif type(val.value) == "string" then
			v = val.value
			l = val.label
		elseif type(val.value) == "table" then
			l = searchoption(val.value, value)
			if l then return l end
		end
		if v == value then
			return l
		end
	end
end

local function getlabel(myitem, value)
	if myitem and (myitem.type == "select" or myitem.type == "multi") then
		local label = searchoption(myitem.option, value)
		if label then return label end
	end
	return tostring(value)
end

function mymodule.displaysectionstart(myitem, page_info, header_level)
	page_info = page_info or {}
	header_level = header_level or page_info.header_level or 1
	if 0 < header_level then
		print('<div class="section'..tostring(header_level)..'" id="section_'..html.html_escape(myitem.name)..'">')
		print('<h'..tostring(header_level)..'>'..html.html_escape(myitem.label)..'</h'..tostring(header_level)..'>')
	end
	return header_level
end

function mymodule.displaysectionend(header_level)
	if 0 < header_level then
		print('</div> <!-- .section'..tostring(header_level)..' -->')
	end
end

function mymodule.incrementheader(header_level)
	if 0 >= header_level then
		return header_level
	else
		return tonumber(header_level)+1
	end
end

function mymodule.displayinfo(myitem)
	if myitem.descr then io.write('<p class="descr">' .. string.gsub(html.html_escape(myitem.descr), "\n", "<br/>") .. '</p>') end
	if myitem.default == false or myitem.default then io.write('<p class="descr">Default:' .. string.gsub(html.html_escape(getlabel(myitem, myitem.default)), "\n", "<br/>") .. '</p>') end
	if myitem.errtxt then io.write('<p class="error">' .. string.gsub(html.html_escape(myitem.errtxt), "\n", "<br/>") .. '</p>') end
end

function mymodule.displayitemstart(myitem, page_info, header_level)
	myitem = myitem or {}
	page_info = page_info or {}
	header_level = header_level or page_info.header_level or 1
	if 0 <= header_level then
		io.write('<div class="item')
		if myitem.errtxt then
			io.write(' error')
		end
		io.write('"><label class="left')
		if myitem.id then
			io.write('" for="'..myitem.id)
		end
		io.write('">')
	end
	return header_level
end

function mymodule.displayitemmiddle(myitem, page_info, header_level)
	page_info = page_info or {}
	header_level = header_level or page_info.header_level or 1
	if 0 <= header_level then
		io.write('</label>')
		io.write('<div class="right">')
	end
end

function mymodule.displayitemend(myitem, page_info, header_level)
	myitem = myitem or {}
	page_info = page_info or {}
	header_level = header_level or page_info.header_level or 1
	mymodule.displayinfo(myitem)
	if 0 <= header_level then
		io.write('</div></div><!-- end .item -->')
	end
end

function mymodule.displayitem(myitem, page_info, header_level, name, group)
	if not myitem then return end
	page_info = page_info or {}
	myitem.name = name or myitem.name or ""
	if group and group ~= "" then myitem.name = group.."."..myitem.name end
	if myitem.hidden then
		myitem.type = "hidden"
	end
	if myitem.type == "form" or myitem.type == "link" then
		header_level = mymodule.displaysectionstart(myitem, page_info, header_level)
		mymodule.displayform(myitem, page_info, mymodule.incrementheader(header_level))
		mymodule.displaysectionend(header_level)
	elseif myitem.type == "group" then
		header_level = mymodule.displaysectionstart(myitem, page_info, header_level)
		mymodule.displayinfo(myitem)
		local seqorder = {}
		local order = {}
		for name,item in pairs(myitem.value) do
			if tonumber(item.seq) then
				seqorder[#seqorder+1] = {seq=tonumber(item.seq), name=name}
			else
				order[#order+1] = name
			end
		end
		table.sort(seqorder, function(a,b) if a.seq ~= b.seq then return a.seq > b.seq else return a.name > b.name end end)
		table.sort(order)
		for i,val in ipairs(seqorder) do
			table.insert(order, 1, val.name)
		end
		for x,name in ipairs(order) do
			if myitem.value[name] then
				mymodule.displayitem(myitem.value[name], page_info, mymodule.incrementheader(header_level), name, myitem.name)
			end
		end
		mymodule.displaysectionend(header_level)
	elseif myitem.key and not myitem.readonly then
		mymodule.displayformitem(myitem, name, header_level, group)
	elseif myitem.type ~= "hidden" then
		if myitem.errtxt then
			if myitem.class then
				myitem.class = myitem.class.." error"
			else
				myitem.class = "error"
			end
		end
		header_level = mymodule.displayitemstart(myitem, page_info, header_level)
		if 0 <= header_level then
			io.write(html.html_escape(myitem.label))
		end
		mymodule.displayitemmiddle(myitem, page_info, header_level)
		class = ""
		if myitem.class then
			class = ' class="'..html.html_escape(myitem.class)..'"'
		end
		local value = tostring(myitem.value)
		if type(myitem.value) == "table" then
			value = table.concat(myitem.value, "\n")
		end
		io.write("<p"..class..">"..string.gsub(html.html_escape(value), "\n", "<br/>") .. "</p>\n")
		mymodule.displayitemend(myitem, page_info, header_level)
	end
end

function mymodule.displayformitem(myitem, name, header_level, group)
	if not myitem then return end
	myitem.name = name or myitem.name or ""
	if group and group ~= "" then myitem.name = group.."."..myitem.name end
	if myitem.errtxt then
		if myitem.class then
			myitem.class = myitem.class.." error"
		else
			myitem.class = "error"
		end
	end
	if myitem.hidden then
		myitem.type = "hidden"
	end
	if myitem.type ~= "hidden" and myitem.type ~= "group" then
		-- Set the id so the label 'for' can point to it
		myitem.id = myitem.id or myitem.name
		header_level = mymodule.displayitemstart(myitem, nil, header_level)
		if 0 <= header_level then
			io.write(html.html_escape(myitem.label))
		end
		mymodule.displayitemmiddle(myitem, nil, header_level)
	end
	if myitem.type == "group" then
		header_level = mymodule.displaysectionstart(myitem, nil, header_level)
		mymodule.displayinfo(myitem)
		mymodule.displayformcontents(myitem, mymodule.incrementheader(header_level), myitem.name)
		mymodule.displaysectionend(header_level)
	elseif myitem.type == "multi" then
		myitem.type = "select"
		myitem.multiple = "true"
		local tempname = myitem.name
		myitem.name = tempname.."[]"
		io.write((html.form[myitem.type](myitem) or ""))
		myitem.name = tempname
		myitem.type = "multi"
--[[
		-- FIXME multiple select doesn't work in haserl, so use series of checkboxes
		myitem.class = nil
		local tempname = myitem.name
		local tempval = myitem.value or {}
		local reverseval = {}
		for x,val in ipairs(tempval) do
			reverseval[val] = x
		end
		local reverseopt = {}
		for x,val in ipairs(myitem.option) do
			local v,l
			if type(val) == "string" then
				v = val
				l = val
			elseif type(val.value) == "string" then
				v = val.value
				l = val.label
				myitem.disabled = val.disabled
			end
			reverseopt[v] = x
			myitem.value = v
			myitem.checked = reverseval[v]
			myitem.name = tempname .. "." .. x
			io.write(html.form.checkbox(myitem) .. html.html_escape(l) .. "<br>\n")
		end
		-- Check for values not in options
		if myitem.errtxt then
			myitem.class = "error"
			io.write('<p class="error">\n')
		end
		for x,val in ipairs(tempval) do
			if not reverseopt[val] then
				myitem.value = val
				myitem.checked = true
				io.write(html.form.checkbox(myitem) .. html.html_escape(val) .. "<br>\n")
			end
		end
		if myitem.errtxt then
			io.write('</p>\n')
		end
		myitem.name = tempname
		myitem.value = tempval
--]]
	elseif myitem.type == "boolean" then
		local tempval = myitem.value
		if (myitem.value == true) then myitem.checked = "" end
		if (myitem.readonly == true) then myitem.disabled = true end
		myitem.value = "true"
		io.write(html.form.checkbox(myitem))
		myitem.value = tempval
	elseif myitem.type == "list" then
		local tempval = myitem.value
		myitem.value = table.concat(myitem.value, "\n")
		io.write(html.form.longtext(myitem))
		myitem.value = tempval
	elseif myitem.type == "select" and myitem.readonly then
		local tempval = myitem.value
		local label = searchoption(myitem.option, myitem.value)
		if label then myitem.value = label end
		io.write((html.form.text(myitem) or ""))
		myitem.value = tempval
	elseif html.form[myitem.type] then
		io.write((html.form[myitem.type](myitem) or ""))
	else
		io.write((string.gsub(html.html_escape(tostring(myitem.value)), "\n", "<br/>")))
	end
	if myitem.type ~= "hidden" and myitem.type ~= "group" then
		mymodule.displayitemend(myitem, nil, header_level)
	end
end

function mymodule.displayformstart(myform, page_info)
	if not myform then return end
	if not myform.action and page_info then
		myform.action = page_info.script .. page_info.prefix .. page_info.controller .. "/" .. page_info.action
	end
	mymodule.displayinfo(myform)
	io.write('<form action="' .. html.html_escape(myform.action) .. '" id="' .. html.html_escape(myform.id or page_info.action) .. '" ')
	if myform.enctype and myform.enctype ~= "" then
		io.write('enctype="'..html.html_escape(myform.enctype)..'" ')
	end
	io.write('method="post">\n')
	if myform.value.redir then
		mymodule.displayformitem(myform.value.redir, "redir")
	end
end

function mymodule.displayformcontents(myform, header_level, group)
	if not myform then return end
	local order = {}
	local tmporder = {}
	for name,item in pairs(myform.value) do
		if tonumber(item.seq) then
			tmporder[#tmporder+1] = {seq=tonumber(item.seq), name=name}
		end
	end
	if #tmporder>0 then
		table.sort(tmporder, function(a,b) if a.seq ~= b.seq then return a.seq < b.seq else return a.name < b.name end end)
		for i,val in ipairs(tmporder) do
			order[#order+1] = val.name
		end
	end
	local reverseorder= {["redir"]=0}
	if #order>0 then
		for x,name in ipairs(order) do
			reverseorder[name] = x
			if myform.value[name] then
				myform.value[name].name = name
				mymodule.displayformitem(myform.value[name], nil, header_level, group)
			end
		end
	end
	for name,item in pairs(myform.value) do
		if nil == reverseorder[name] then
			item.name = name
			mymodule.displayformitem(item, nil, header_level, group)
		end
	end
end

function mymodule.displayformend(myform, header_level)
	if not myform then return end
	local option = myform.submit or myform.option
	header_level = mymodule.displayitemstart(nil, nil, header_level)
	if 0 == header_level then
		io.write(html.html_escape(myform.label))
	end
	mymodule.displayitemmiddle(nil, nil, header_level)
	if type(option) == "table" then
		for i,v in ipairs(option) do
			io.write('<input class="submit" type="submit" ')
			if "form" == myform.type then
				io.write('name="submit" ')
			end
			io.write('value="' .. html.html_escape(v) .. '">\n')
		end
	else
		io.write('<input class="'..html.html_escape(myform.class)..' submit" type="submit" ')
		if "form" == myform.type then
			io.write('name="submit" ')
		end
		io.write('value="' .. html.html_escape(myform.submit or myform.option) .. '">\n')
	end
	mymodule.displayitemend(nil, nil, header_level)
	io.write('</form>\n')
end

function mymodule.displayform(myform, page_info, header_level)
	if not myform then return end
	mymodule.displayformstart(myform, page_info)
	mymodule.displayformcontents(myform, header_level)
	mymodule.displayformend(myform, header_level)
end

function mymodule.displaycommandresults(commands, session, preserveerrors)
	local cmdresult = {}
	for i,cmd in ipairs(commands) do
		if session[cmd.."result"] then
			cmdresult[#cmdresult + 1] = cfe(session[cmd.."result"])
			if not preserveerrors or not session[cmd.."result"].errtxt then
				session[cmd.."result"] = nil
			end
		end
	end
	if #cmdresult > 0 then
		io.write('<div class="command-results"><h1>Command Result</h1>')
		for i,result in ipairs(cmdresult) do
			if type(result.value) == "string" and result.value ~= "" then io.write('<p>' .. string.gsub(html.html_escape(result.value), "\n", "<br/>") .. "</p>") end
			if result.descr then io.write('<p class="descr">' .. string.gsub(html.html_escape(result.descr), "\n", "<br/>") .. '</p>') end
			if result.errtxt then io.write('<p class="error">' .. string.gsub(html.html_escape(result:print_errtxt()), "\n", "<br/>") .. '</p>') end
		end
		io.write('</div><!-- end .command-results -->')
	end
end

-- Divide up data into pages of size pagesize
-- clientdata can be a page number or a table where clientdata.page is the page number
function mymodule.paginate(data, clientdata, pagesize)
	local subset = data
	local page_data = { numpages=1, page=1, pagesize=pagesize, num=#data }
	if #data > pagesize then
		page_data.numpages = math.floor((#data + pagesize -1)/pagesize)
		if clientdata and clientdata.page and tonumber(clientdata.page) then
			page_data.page = tonumber(clientdata.page)
		elseif clientdata and tonumber(clientdata) then
			page_data.page = tonumber(clientdata)
		end
		if page_data.page > page_data.numpages then
			page_data.page = page_data.numpages
		elseif page_data.page < 0 then
			page_data.page = 0
		end
		if page_data.page > 0 then
			subset = {}
			for i=((page_data.page-1)*pagesize)+1, page_data.page*pagesize do
				table.insert(subset, data[i])
			end
		end
	end
	return subset, page_data
end

function mymodule.displaypagination(page_data, page_info)
	local min, max
	if page_data.page == 0 then
		min = 1
		max = page_data.num
	else
		min = math.min(((page_data.page-1)*page_data.pagesize)+1, page_data.num)
		max = math.min(page_data.page*page_data.pagesize, page_data.num)
	end
	if min == max then
		io.write("Record "..min.." of "..page_data.num.."\n")
	else
		io.write("Records "..min.."-"..max.." of "..page_data.num.."\n")
	end

	if page_data.numpages > 1 then
		-- Pre-determine the links for each page
		local link = page_info.script .. page_info.orig_action .. "?"
		local clientdata = {}
		function serialize_clientdata(cltdata, prefix)
			for name,val in pairs(cltdata) do
				if name ~= "sessionid" and name ~= "page" then
					if (type(val) == "table") then
						serialize_clientdata(val, prefix..name..".")
					else
						clientdata[#clientdata + 1] = prefix..name.."="..html.url_encode(val)
					end
				end
			end
		end
		serialize_clientdata(page_info.clientdata, "")
		if #clientdata > 0 then
			link = link .. table.concat(clientdata, "&") .. "&"
		end
		link = link.."page="

		function pagelink(page)
			io.write(html.link{value=link..page, label=page}.."\n")
		end

		-- Print out < 1 n-50 n-25 n-10 n-2 n-1 n n+1 n+2 n+10 n+25 n+50 numpages >
		io.write('<div align="right">Pages:')
		local p = page_data.page
		if p > 1 then
			io.write('<a href='..link..(p-1)..'><img SRC="'..html.html_escape(page_info.staticdir)..'/tango/16x16/actions/go-previous.png" HEIGHT="16" WIDTH="16"></a>\n')
		end
		if p ~= 1 then
			pagelink(1)
		end
		local links = {(p-3)-(p-3)%10, p-2, p-1, p, p+1, p+2, (p+12)-(p+12)%10}
		table.insert(links, 1, links[1]-1-(links[1]-1)%25)
		table.insert(links, 1, links[1]-1-(links[1]-1)%50)
		table.insert(links, links[#links]+25-links[#links]%25)
		table.insert(links, links[#links]+50-links[#links]%50)
		for i,num in ipairs(links) do
			if num==p and p~=0 then
				io.write(p.."\n")
			elseif num>1 and num<page_data.numpages then
				pagelink(num)
			end
		end
		if p<page_data.numpages then
			pagelink(page_data.numpages)
			if p~= 0 then
				io.write('<a href='..link..(p+1)..'><img SRC="'..html.html_escape(page_info.staticdir)..'/tango/16x16/actions/go-next.png" HEIGHT="16" WIDTH="16"></a>\n')
			end
		end
		if p~=0 then
			io.write(html.link{value=link.."0", label="all"}.."\n")
		end
		io.write("</div>")
	end
end

-- give a cfe and get back a string of what is inside
-- great for troubleshooting and seeing what is really being passed to the view
function mymodule.cfe_unpack ( a )
	if type(a) == "table" then
		value = session.serialize("cfe", a)
		value = "<pre>" .. html.html_escape(value) .. "</pre>"
		return value
	end
end

return mymodule
