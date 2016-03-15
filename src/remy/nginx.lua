-- Remy - Nginx compatibility
-- Copyright (c) 2014 Felipe Daragon
-- License: MIT

local ngx = require "ngx"
local remy = require "remy"
local output_buffer = {}

-- Buffer output to allow changing the header up until M.finish is called
-- See https://github.com/openresty/lua-nginx-module#ngxheaderheader
local function buffered_print(_, ...)
	table.insert(output_buffer, {...})
end

-- TODO: implement all functions from mod_lua's request_rec
local request = {
	-- ENCODING/DECODING FUNCTIONS
	base64_decode = function(_,...) return ngx.decode_base64(...) end,
	base64_encode = function(_,...) return ngx.encode_base64(...) end,
	escape = function(_,...) return ngx.escape_uri(...) end,
	unescape = function(_,...) return ngx.unescape_uri(...) end,
	md5 = function(_,...) return ngx.md5(...) end,
	-- REQUEST PARSING FUNCTIONS
	parseargs = function(_) return ngx.req.get_uri_args(), {} end,
	parsebody = function(_) return ngx.req.get_post_args(), {} end,
	requestbody = function(_,...) return ngx.req.get_body_data() end,
	-- REQUEST RESPONSE FUNCTIONS
	puts = buffered_print,
	write = buffered_print
}

local M = {
  mode = "nginx",
  request = request
}

function M.init()
	local r = request
	local filename = ngx.var.request_filename
	local uri = ngx.var.uri
	apache2.version = M.mode.."/"..ngx.var.nginx_version
	r = remy.loadrequestrec(r)
	r.headers_out = ngx.resp.get_headers()
	r.headers_in = ngx.req.get_headers()
	local auth = ngx.decode_base64((r.headers_in["Authorization"] or ""):sub(7))
	local _,_,user,pass = auth:find("([^:]+)%:([^:]+)")
	r.started = ngx.req.start_time
	r.method = ngx.var.request_method
	r.args = remy.splitstring(ngx.var.request_uri,'?')
	r.banner = M.mode.."/"..ngx.var.nginx_version
	r.basic_auth_pw = pass
	r.canonical_filename = filename
	r.context_document_root = ngx.var.document_root
	r.document_root = r.context_document_root
	r.filename = filename
	r.hostname = ngx.var.hostname
	r.port = ngx.var.server_port
	r.protocol = ngx.var.server_protocol
	r.range = r.headers_in["Range"]
	r.server_name = r.hostname
	r.the_request = r.method.." "..ngx.var.request_uri.." "..r.protocol
	r.unparsed_uri = uri
	r.uri = uri
	r.user = user
	r.useragent_ip = ngx.var.remote_addr
end

function M.contentheader(content_type)
	request.content_type = content_type
	ngx.header.content_type = content_type
end

function M.finish(code)
	-- Set the headers
	if request.content_type and not ngx.header.content_type then
		ngx.header["Content-Type"] = request.content_type
	end
	for k, v in pairs(request.headers_out) do
		ngx.header[k] = v
	end

	-- Print the data & Clear the buffer
	ngx.print(output_buffer)
	output_buffer = {}

	-- TODO: translate request_rec's exit code and call ngx.exit(code)
end

return M