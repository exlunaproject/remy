local remy_demo = {}

-- This page will work with mod_lua, mod_pLua & CGILua
function remy_demo.index(page)
  local t = {}
  t.server = page.r.banner
  t.ip = page.r.useragent_ip
  page:render('index',{server=t.server,ip=t.ip})
end

-- This one will work only with CGILua
function remy_demo.cgi(page)
  local t = {}
  t.server = cgilua.servervariable('SERVER_SOFTWARE')
  t.ip = cgilua.servervariable('REMOTE_ADDR')
  page:render('index',{server=t.server,ip=t.ip})
end

return remy_demo