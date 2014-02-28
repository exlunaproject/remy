# Remy #

Remy runs web applications built for mod_lua in different environments like mod_pLua or CGILua, which can work with other web servers than Apache. The goal is to support and emulate the mod_lua API, including the request_rec structure, its built-in functions and other required functionality.

This is a work in progress. Remy is already able to run Sailor (https://github.com/Etiene/sailor), a Lua-based MVC framework which originally uses mod_lua.

See the examples/sailor folder for sample code.

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