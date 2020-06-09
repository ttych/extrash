#!/bin/sh
# -*- mode: sh -*-


SCRIPT_NAME="${0##*/}"


has_ruby()
{
    which ruby >/dev/null 2>/dev/null ||
        echo >&2 No ruby available
}

uuid_gen()
{
    has_ruby || return 1
    ruby -rsecurerandom -e 'puts SecureRandom.uuid'
}

file_inspect()
{
    has_ruby || return 1
    ruby -e "puts File.read('$1').inspect"
}



### main

case "$SCRIPT_NAME" in
    uuid_gen|file_inspect)
        "$SCRIPT_NAME" "$@"
        ;;
esac
