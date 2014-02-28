-- Remy 0.1
-- Copyright (c) 2014 Felipe Daragon
-- License: MIT (http://opensource.org/licenses/mit-license.php)
--
-- Remy runs web applications built for mod_lua in different
-- environments like mod_pLua or CGILua, which can work with other web 
-- servers than Apache. The goal is to support and emulate the mod_lua
-- API, including the request_rec structure, its built-in functions and
-- other required functionality.

remy = {
	MODE_CGILUA = 0,
	MODE_MOD_PLUA = 1
}

-- The values below will be updated during runtime
remy.config = {
	banner = "Apache/2.4.7 (Unix)",
	hostname = "localhost",
	uri = "/index.lua"
}

-- apache2 Package constants
remy.apache2 = {
	-- Internal constants from include/httpd.h
	OK = 0,
	DECLINED = -1,
	DONE = -2,
	version = remy.config.banner,
	-- Other HTTP status codes are not yet implemented in mod_lua
	HTTP_MOVED_TEMPORARILY = 302,
	-- Internal constants used by mod_proxy
	PROXYREQ_NONE = 0,
	PROXYREQ_PROXY = 1,
	PROXYREQ_REVERSE = 2,
	PROXYREQ_RESPONSE = 3,
	-- Internal constants used by mod_authz_core
	AUTHZ_DENIED = 0,
	AUTHZ_GRANTED = 1,
	AUTHZ_NEUTRAL = 2,
	AUTHZ_GENERAL_ERROR = 3,
	AUTHZ_DENIED_NO_USER = 4
}

-- mod_lua's request_rec
-- The values below will be updated during runtime
local request_rec_fields = {
	allowoverrides = " ",
	ap_auth_type = nil,
	args = nil,
	assbackwards = false,
	auth_name = "",
	banner = remy.config.banner,
	basic_auth_pw = "",
	canonical_filename = nil,
	content_encoding = nil,
	content_type = nil,
	context_prefix = nil,
	context_document_root = nil,
	document_root = nil,
	err_headers_out = {},
	filename = nil,
	handler = "lua-script",
	headers_in = {},
	headers_out = {},
	hostname = remy.config.hostname,
	is_https = false,
	is_initial_req = true,
	limit_req_body = 0,
	log_id = nil,
	method = "GET",
	notes = {},
	options = "Indexes FollowSymLinks ",
	path_info = "",
	port = 80,
	protocol = "HTTP/1.1",
	proxyreq = "PROXYREQ_NONE",
	range = nil,
	remaining = 0,
	server_built = "Nov 26 2013 15:46:56",
	server_name = remy.config.hostname,
	some_auth_required = false,
	subprocess_env = {},
	started = 1393508507,
	status = 200,
	the_request = "GET "..remy.config.uri.." HTTP/1.1",
	unparsed_uri = remy.config.uri,
	uri = remy.config.uri,
	user = nil,
	useragent_ip = "127.0.0.1"
}

function remy.init(mode)
	if mode == nil then
		mode = remy.detect()
	end
	if mode == remy.MODE_CGILUA then
		require "remy.cgilua"
	elseif mode == remy.MODE_MOD_PLUA then
		require "remy.mod_plua"
	end
	remy.initmode()
end

-- Detects the Lua environment
function remy.detect()
	local mode = nil
	if cgilua ~= nil then
		mode = remy.MODE_CGILUA
	elseif getEnv ~= nil then
		local env = getEnv()
		if env["pLua-Version"] ~= nil then
			mode = remy.MODE_MOD_PLUA
		end
	end
	return mode
end

function remy.run(handle)
	local code = handle(remy.request)
	remy.finish(code)
end

-- Load the default request_rec fields
function remy.loadrequestrec(r)
	for k,v in pairs(request_rec_fields) do r[k] = v end
	return r
end

function remy.splitstring(s, delimiter)
	result = {}
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match)
	end
	return result
end
