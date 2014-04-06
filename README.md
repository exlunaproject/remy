# Remy #

This project started as a simple mod_lua emulator, allowing to run web applications built for mod_lua in alternative environments that allow to run server-side Lua code. As such, it is able to support and emulate the mod_lua API, including the request_rec structure and some of its built-in functions. Currently it is being refactored to work both as an abstract wrapper to several alternative web server environments and as a mod_lua emulator.

This is a work in progress, not suitable for production environments yet. Remy is already able to run Sailor (https://github.com/Etiene/sailor), a Lua-based MVC framework which originally uses mod_lua in the environments listed below.

## Supported Environments #

* Any web server with CGILua https://github.com/keplerproject/cgilua Tested with:
 * Apache
 * Civetweb https://github.com/sunsetbrew/civetweb
 * Mongoose https://github.com/cesanta/mongoose
 * Untested: IIS
* Apache with mod_lua http://www.modlua.org/
* Apache with mod_plua https://github.com/Humbedooh/mod_pLua
* Nginx with ngx_lua (HttpLuaModule) https://github.com/nginx/nginx

## Planned Environments #

* Lighttpd

## Usage #

``` lua
require "remy"
require "string"

function handle(r)
    r.content_type = "text/plain"

    if r.method == 'GET' then
        r:puts("Hello Lua World!\n")
        for k, v in pairs( r:parseargs() ) do
            r:puts( string.format("%s: %s\n", k, v) )
        end
    elseif r.method == 'POST' then
        r:puts("Hello Lua World!\n")
        for k, v in pairs( r:parsebody() ) do
            r:puts( string.format("%s: %s\n", k, v) )
        end
    end
    return apache2.OK
end

remy.init()
remy.contentheader("text/plain")
remy.run(handle)
```

## License #

Remy is licensed under the MIT license (http://opensource.org/licenses/MIT)

(c) Felipe Daragon, 2014