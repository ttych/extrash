#!/bin/sh
# -*- mode: sh -*-


TRUE()
{
    return 0
}

FALSE()
{
    return 1
}


##################################################
# file monitore
##################################################
file_mon()
(
    file_mon__usage="fmon [-d] [-F] [-c command] [-p] [-s X] path1 path2 path..."
    file_mon__file=TRUE
    file_mon__directory=FALSE
    file_mon__sleep=5
    file_mon__separator=
    file_mon__command='echo "%s"'
    file_mon__print=FALSE

    file_mon__hash=$(which md5sum)
    [ -z "$file_mon__hash" ] && file_mon__hash=$(which md5)
    [ -z "$file_mon__hash" ] && file_mon__hash=$(which sha256sum)
    [ -z "$file_mon__hash" ] && file_mon__error="no checksum method" && return 1

    OPTIND=1
    while getopts :hFdc:ps:S: opt; do
	    case $opt in
	        h) printf "%s\n" "$file_mon__usage"; return 0 ;;
            F) file_mon__file=FALSE ;;
	        d) file_mon__directory=TRUE ;;
	        c) file_mon__command="$OPTARG" ;;
	        p) file_mon__print=TRUE ;;
	        s) file_mon__sleep="$OPTARG" ;;
	        S) file_mon__separator="$OPTARG" ;;
	    esac
    done
    shift $(($OPTIND - 1))

    file_mon__init=TRUE
    while true; do
        for file_mon__p; do
            for file_mon__p_f in $(find "$file_mon__p"); do
                ($file_mon__file && test -f "$file_mon__p_f") || \
                    ($file_mon__directory && test -d "$file_mon__p_f") || \
                    continue
                file_mon__p_f_hash=$(echo "$file_mon__p_f" | $file_mon__hash)
                file_mon__p_f_hash=${file_mon__p_f_hash%% *}
                file_mon__p_f_time=$(stat -c %Z "$file_mon__p_f")
                eval file_mon__p_f_last_time=\$file_mon__p_f_${file_mon__p_f_hash}
                if ! $file_mon__init; then
                    if [ -z "$file_mon__p_f_last_time" ] ||
                           [ "$file_mon__p_f_last_time" != "$file_mon__p_f_time" ]; then
                        # print
                        $file_mon__print && printf "%s\n" "$file_mon__p_f"
                        # command
                        [ -n "$file_mon__command" ] && eval $(printf "$file_mon__command" "$file_mon__p_f")
                        # separator
                        case $file_mon__separator in
                            line) echo '========================================' ;;
                            clear) clear ;;
                        esac
                    fi
                fi
                eval file_mon__p_f_${file_mon__p_f_hash}="${file_mon__p_f_time}"
            done
        done
        file_mon__init=FALSE
        sleep $file_mon__sleep
    done
)
