#!/usr/bin/env bash

if ! which luarocks > /dev/null; then
  ( >&2 echo "luarocks binary not found in PATH")
  exit 1
fi

luainstall() {
  luarocks --lua-version=5.1 --local install ${1}
}

luainstall fennel
luainstall etlua
luainstall luafilesystem
luainstall lunamark
luainstall toml
luainstall lua-cjson
