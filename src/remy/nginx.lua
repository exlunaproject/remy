-- Remy - Nginx compatibility
-- Copyright (c) 2014 Felipe Daragon
-- License: MIT

local ngx = require "ngx"
local remy = require "remy"
local file = require "remy.file_obj"
local output_buffer = {}
local files = {}

-- Settings for streaming multipart/form-data
local chunk_size = 16384 -- Bytes
local socket_timeout = 5000 -- Milliseconds

-- Buffer output to allow changing the header up until M.finish is called
-- See https://github.com/openresty/lua-nginx-module#ngxheaderheader
local function buffered_print(_, ...)
	table.insert(output_buffer, {...})
end

-- Manually parses the request body to handle files
-- Buffers any files to disk
local function load_req_body()

	-- Nginx lower cases all the keys
	local header = ngx.req.get_headers()

	-- Check the header for a boundary
	local boundary = (header["content-type"] or ""):match("boundary=(.+)$")

	-- If there's no boundary, don't worry about using a socket
	-- Parse the body the normal way
	if not boundary then
		ngx.req.read_body()
		return ngx.req.get_post_args(), {}
	end

	-- Otherwise try to open a socket
	local socket, err = ngx.req.socket()
	if not socket then
		ngx.say("Failed to open socket: ", err)
		ngx.exit(500)
	end
	socket:settimeout(socket_timeout)

	-- CRLF is the standard for HTTP requests
	local stream, err = socket:receiveuntil("\r\n--" .. boundary)
	if not stream then
		ngx.say("Failed to open stream: ", err)
		ngx.exit(500)
	end

	local POST = {}

	-- Read the data
	while true do

		-- Read a line
		local header = socket:receive()
		if not header then
			break
		end
		local key = header:match("name=\"(.-)\"")

		-- If this is just a boundary, it will ignore it
		if key then
			local value = ""

			-- Check if it's a file
			local filename = header:match("filename=\"(.-)\"")
			if filename then
				local content_type = socket:receive():match("Content%-Type: ?(.+)$")

				-- Build the file object
				value = file.new(filename, content_type)
			end

			-- Stream the data, skipping the blank line
			socket:receive()
			while true do
				local data, err = stream(chunk_size)
				if err then
					ngx.say("Failed to read data stream: ", err)
					ngx.exit(500)
				elseif not data then
					break
				end

				-- Write to file, or save to variable
				if type(value) == "table" then

					-- Convert the line endings respective to host OS
					value.handle:write(value.path:match("/") and data:gsub("\r\n", "\n") or data)
				else
					value = value .. data
				end
			end

			-- Close the file
			if type(value) == "table" then
				value.handle:close()
				value.handle = nil
			end

			-- Append POST & files list if necessary
			-- Mimics behaviour of ngx.req.get_post_args()
			if POST[key] and (type(POST[key]) ~= "table" or POST[key].name) then
				POST[key] = {POST[key], value}
			elseif type(POST[key]) == "table" then
				table.insert(POST[key], value)
			else
				POST[key] = value
			end
			if type(value) == "table" then table.insert(files, value) end
		end
	end

	return POST, {}
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
	parsebody = load_req_body,
	requestbody = function(_,...)
		-- Make sure the request body has been read
		ngx.req.read_body()
		return ngx.req.get_body_data()
	end,
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
	-- Set status code
	ngx.status = code

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

	-- Delete temporary files
	for _, file in pairs(files) do
		os.remove(file.path)
	end
	files = {}

	-- TODO: translate request_rec's exit code and call ngx.exit(code)
end

return M
