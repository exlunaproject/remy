# Remy #

Remy (the R emulator) is a simple mod_lua emulator, allowing to run web applications built for mod_lua in alternative environments that allow to run server-side Lua code. As such, it is able to support and emulate the mod_lua API, the request_rec structure and some of its built-in functions.

This is a work in progress, an may not be suitable for production environments yet.

Remy was developed as part of [Sailor](https://github.com/Etiene/sailor), a Lua-based MVC framework which originally uses mod_lua, and is already able to run mod_lua apps in a variety of environments (listed below).

## Supported Environments #

* Any web server with [CGILua](https://github.com/keplerproject/cgilua) Tested with:
 * Apache
 * [Civetweb](https://github.com/bel2125/civetweb)
 * [Mongoose](https://github.com/cesanta/mongoose)
 * Untested: IIS
* Apache with [mod_lua](http://www.modlua.org/)
* Apache with [mod_plua](https://github.com/Humbedooh/mod_pLua)
* Lighttp with [mod_magnet](http://redmine.lighttpd.net/projects/1/wiki/Docs_ModMagnet)
* [Lwan Web Server](http://lwan.ws/)
* Nginx with [ngx_lua](https://github.com/nginx/nginx) (HttpLuaModule)

## Planned Environments #

* IIS with [LuaScript](http://na-s.jp/LuaScript/)

## Usage #

``` lua
local remy = require "remy"

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

(c) Felipe Daragon, 2014-2015