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
RGR_AUTO=FALSE
RGR_CHECK=TRUE
RGR_TEST_AUTOCREATE=FALSE
RGR_DEFAULT_PRUNE='-P .git -P .tox -P __pycache__ -P .idea -P node_modules -P bootsnap-compile-cache'

rgr()
{
    rgr__usage="rgr [-p path_to_prune] [-P: no_default_prune] [-A: no_auto] [-C: no_check] [-t: test_autocreate]"
    rgr__base_prune="$RGR_DEFAULT_PRUNE"
    rgr__prune=
    rgr__auto='-a'
    rgr__check='-c'
    rgr__test_autocreate='-T'
    OPTIND=1
    while getopts :hPp:ACt opt; do
        case $opt in
            h) printf "%s\n" "$rgr__usage"; return 0 ;;
            p) rgr__prune="$rgr__prune -P $OPTARG" ;;
            P) rgr__base_prune= ;;
            A) rgr__auto='-A' ;;
            C) rgr__check='-C' ;;
            t) rgr__test_autocreate='-t' ;;
        esac
    done
    shift $(($OPTIND - 1))

    file_mon -s "$RGR_DELAY" -c "rgr_on $rgr__auto $rgr__check $rgr__test_autocreate \"%s\"" $rgr__base_prune $rgr__prune "$@"
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
    OPTIND=1
    while getopts :aAcCtT opt; do
        case $opt in
            a) RGR_AUTO=TRUE ;;
            A) RGR_AUTO=FALSE ;;
            c) RGR_CHECK=TRUE ;;
            C) RGR_CHECK=FALSE ;;
            t) RGR_TEST_AUTOCREATE=TRUE ;;
            T) RGR_TEST_AUTOCREATE=FALSE ;;
        esac
    done
    shift $(($OPTIND - 1))

    [ -r "$1" ] || return 1

    rgr_on__status=0
    rgr_on__file="${1#\./}"

    devel_kind_for "$rgr_on__file" || return 1
    rgr_on__kind="$devel_kind_for"

    devel_title "Change on $rgr_on__file [$rgr_on__kind] (`rgr_timestamp`)"

    rgr_cksum "$rgr_on__file"
    rgr_on__cksum="$rgr_cksum"

    rgr_on__status=1
    if "$rgr_on__kind"_rgr "$rgr_on__file" "devel_subtitle"; then
        rgr_cksum "$rgr_on__file"
        if [ "$rgr_cksum" = "$rgr_on__cksum" ]; then
            rgr_stage "$rgr_on__file" &&
                rgr_on__status=0
        else
            devel_subtitle "skip staging for $1 (file changed)"
        fi
    fi

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
