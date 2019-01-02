#!/bin/sh

LUAROCKS_SYSCONFDIR='/usr/local/etc/luarocks' LUA_INIT='package.path="/home/andre_la/git/lua-projs/motor/./../lua_modules/share/lua/5.1,5.3/?.lua;/home/andre_la/git/lua-projs/motor/./../lua_modules/share/lua/5.1,5.3/?/init.lua;"..package.path;package.cpath="/home/andre_la/git/lua-projs/motor/./../lua_modules/lib/lua/5.1,5.3/?.so;"..package.cpath' exec '/usr/local/bin/lua'  "$@"
