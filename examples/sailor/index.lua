-- This script makes Sailor compatible with CGILua & mod_pLua
require "src.sailor"
require "remy"

function handle(r)
	local path = r.filename:match("^@?(.-)/index.lua$")
	r.content_type = "text/html"
	local page = sailor.init(r,path)
	return sailor.route(page)
end

remy.init()
remy.contentheader('text/html')
remy.run(handle)
