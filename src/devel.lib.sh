#!/bin/sh


#%%load%% file.lib.sh
#%%load%% terminal.lib.sh
#%%load%% git.lib.sh


### devel utils

DEVEL_LANG="${DEVEL_LANG:-}"

devel_title()
{
    terminal_set_attr 0  $TERMINAL_BOLD
    #terminal_set_fg $TERMINAL_CYAN
    terminal_set_fg $TERMINAL_YELLOW
    printf "|>>> %s <<<|\n" "$@"
    terminal_set_fg ''
}

devel_subtitle()
{
    terminal_set_attr 0  $TERMINAL_BOLD
    #terminal_set_fg $TERMINAL_CYAN
    terminal_set_fg $TERMINAL_YELLOW
    printf "|  > %s <  |\n" "$@"
    terminal_set_fg ''
}

devel_kind_for()
{
    for devel_kind_for in $DEVEL_LANG; do
        if is_"${devel_kind_for}"_file "$1"; then
            return 0
        fi
    done
    devel_kind_for=
    return 1
}

### rgr - Red Green Refactor

## each lang should implement
## - is_<lang>_file file
## - <lang>_rgr file title_function

RGR_DELAY=2

rgr()
{
    file_mon -s "$RGR_DELAY" -c 'rgr_on "%s"' -P .git "$@"
}

rgr_timestamp()
{
    #date '+%Y-%m-%d %H:%M:%S'
    date '+%H:%M:%S'
}

rgr_cksum()
{
    rgr_cksum=$(md5sum "$1")
    rgr_cksum="${rgr_cksum%% *}"
}

rgr_on()
{
    [ -r "$1" ] || return 1

    rgr_on__status=0
    rgr_on__file="${1#\./}"

    devel_kind_for "$rgr_on__file" || return 1
    rgr_on__kind="$devel_kind_for"

    devel_title "Change on $rgr_on__file [$rgr_on__kind] (`rgr_timestamp`)"

    rgr_cksum "$rgr_on__file"
    rgr_on__cksum="$rgr_cksum"

    if "$rgr_on__kind"_rgr "$rgr_on__file" "devel_subtitle"; then
        rgr_cksum "$rgr_on__file"
        if [ "$rgr_cksum" = "$rgr_on__cksum" ]; then
            rgr_stage "$rgr_on__file"
        else
            devel_subtitle "skip staging for $1 (file changed)"
        fi
    fi

    rgr_on__status="$?"
    if [ $rgr_on__status -eq 0 ]; then
        rgr_on__status_msg=OK
    else
        rgr_on__status_msg=FAILED
    fi

    devel_title "Flow $rgr_on__status_msg for $rgr_on__file [$rgr_on__kind] (`rgr_timestamp`)"

    return $rgr_on__status
}

rgr_stage()
{
    is_inside_git "$1" || return 0
    devel_subtitle "git stage $1"
    git_add "$1"
}