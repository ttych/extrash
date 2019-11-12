#!/bin/sh
# -*- mode: sh -*-

SCRIPT_NAME="${0##*/}"
SCRIPT_RPATH="${0%$SCRIPT_NAME}"
SCRIPT_PATH=`cd "${SCRIPT_RPATH:-.}" && pwd`


### emacs

_emacs_guess()
{
    if [ -z "$_EMACS" ] || [ "$_EMACS" = ":" ]; then
        _EMACS=`command -v emacs`
        [ -z "$_EMACS" ] && _EMACS=`command -v xemacs`
        _EMACS=${_EMACS:-:}
    fi
}
_emacs_guess
_emacs()
{
    $_EMACS "$@"
}

_emacs_reset()
{
    _EMACS=
    _EMACSCLIENT=
}

#e() { emacs -fn -\*-fixed-\*-12-\* "$@" & }
ex()
{
    _emacs "$@" &
}

exq()
{
    ex -quick "$@"
}

et()
{
    _emacs -nw "$@"
}

etq()
{
    et -quick "$@"
}

_emacsclient_guess()
{
    if [ -z "$_EMACSCLIENT" ] || [ "$_EMACSCLIENT" = ":" ]; then
        _EMACSCLIENT=`command -v emacsclient`
        [ -z "$_EMACSCLIENT" ] && _EMACSCLIENT=`command -v xemacsclient`
         _EMACSCLIENT=${_EMACSCLIENT:-:}
    fi
}
_emacsclient_guess

_emacsclient()
{
    $_EMACSCLIENT "$@"
}

# em()
# {
#     ALTERNATE_EDITOR="" TMPDIR="/tmp" _emacsclient --tty "$@"
# }
# emk()
# {
#     em -e '(kill-emacs)'
# }
# emx()
# {
#     em -e '(client-save-kill-emacs)'
# }
# emd()
# {
#     ALTERNATE_EDITOR="" TMPDIR="/tmp" emacs --daemon
# }

ec_c()
{
    TMPDIR="${TMPDIR:-/tmp}" _emacsclient --alternate-editor="$ALTERNATE_EDITOR" "$@"
}
ec_e()
{
    TMPDIR="${TMPDIR:-/tmp}" _emacs --alternate-editor="$ALTERNATE_EDITOR" "$@"
}
ecx()
{
    ec_c --create-frame "$@" &
}
ec()
{
    ec_c --tty "$@"
}
eck()
{
    ec_c -e '(kill-emacs)'
}
ecs()
{
    ec_c -e '(client-save-kill-emacs)'
}
ecd()
{
    ec_e --daemon
}

e()
{
    ec "$@"
}

ESHELL="${ESH_SH_CUR_SHORT}_login_shell"
export ESHELL

etodo()
{
    e "$HOME/org/todo.org"
}

### vim

# g reclamed for git !
#g() { gvim "$@" & }


### sublime

sublime()
{
    LANG=${LANG:-en_US.UTF-8} sublime_text "$@"
}


### rubymine

rubymine()
{
    rubymine.sh "$@"
}


### pycharm
pycharm()
{
    pycharm=`command -v pycharm`
    case $pycharm in
        /*) ;;
        *) pycharm= ;;
    esac
    if [ -n "$pycharm" ]; then
        "$pycharm" "$@"
        return $?
    fi

    pycharm=`command -v pycharm.sh`
    if [ -n "$pycharm" ]; then
        "$pycharm" "$@" &
        return $? # always 0
    fi

    echo >&2 'no pycharm distribution found'
    return 1
}


### main

case "$SCRIPT_NAME" in
    e|e?|e??|etodo) "$SCRIPT_NAME" "$@"
             ;;
esac
