#!/bin/sh
# -*- mode: sh -*-

for home in "${HOME_ALT}" "${HOME}"; do
    if [ -d "$home" ]; then
        GOROOT="$home/local/$(uname -s)/$(uname -m)/go_root"
        GOPATH="$GOROOT/go_root/packages"
    fi
done
export GOROOT GOPATH
