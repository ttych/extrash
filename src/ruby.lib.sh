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


#%%load%% devel.lib.sh


########## ruby

ruby_bundle()
{
    which bundle 2>/dev/null >/dev/null || {
        echo >&2 "missing bundle command"
        return 1
    }
    bundle "$@"
}

ruby_exec()
{
    if [ -r 'Gemfile' ]; then
        ruby_bundle exec "$@"
    else
        "$@"
    fi
}

ruby_ruby()
{
    ruby_exec ruby "$@"
}

ruby_rake()
{
    [ -r 'Rakefile' ] || return 1
    ruby_exec rake "$@"
}

ruby_rubocop()
{
    which rubocop 2>/dev/null >/dev/null || {
        echo >&2 "missing rubocop command"
        return 0
    }
    ruby_exec rubocop -f fu "$1"
}

ruby_reek()
{
    which reek 2>/dev/null >/dev/null || {
        echo >&2 "missing reek command"
        return 0
    }
    ruby_exec reek "$1"
}

ruby_flay()
{
    which flay 2>/dev/null >/dev/null || {
        echo >&2 "missing flay command"
        return 0
    }
    echo FIXME flay ...
}

ruby_flay_all_rb()
{
    which flay 2>/dev/null >/dev/null || {
        echo >&2 "missing flay command"
        return 0
    }
    ruby_flay_all_rb=.
    [ -d "lib" ] && ruby_flay_all_rb=lib

    find "$ruby_flay_all_rb" -name \*.rb | xargs flay
}

ruby_flog()
{
    which flog 2>/dev/null >/dev/null || {
        echo >&2 "missing flog command"
        return 0
    }
    echo FIXME flog ...
}

ruby_flog_all_rb()
{
    which flog 2>/dev/null >/dev/null || {
        echo >&2 "missing flog command"
        return 0
    }
    ruby_flog_all_rb=.
    [ -d "lib" ] && ruby_flog_all_rb=lib

    find "$ruby_flog_all_rb" -name \*.rb | xargs flog
}

ruby_bundle_install()
{
    ruby_bundle install
}


########## rgr

DEVEL_LANG="${DEVEL_LANG:+$DEVEL_LANG }ruby gemfile"

is_ruby_file()
{
    [ -d "$1" ] && return 1

    case "$1" in
        *.rb)
            return 0
    esac
    return 1
}

is_gemfile_file()
{
    [ -d "$1" ] && return 1

    case "$1" in
        "Gemfile"|*.gemspec)
            return 0
    esac
    return 1
}

gemfile_rgr()
{
    ruby_rgr_bundle_install "$@" &&
        ruby_rgr_rubocop "$@"
}

ruby_rgr_bundle_install()
{
    "${2:-:}" "bundle install"
    ruby_bundle_install
}

ruby_rgr()
{
    ruby_rgr_test "$@" &&
        ruby_rgr_rubocop "$@" &&
        ruby_rgr_reek "$@" &&
        ruby_rgr_flay "$@" &&
        ruby_rgr_flog "$@"
}

ruby_rgr_rubocop()
{
    "${2:-:}"  "rubocop $1"
    ruby_rubocop "$1"
}

ruby_rgr_reek()
{
    "${2:-:}"  "reek $1"
    ruby_reek "$1"
}

ruby_rgr_flay()
{
    "${2:-:}" "flog *rb"
    ruby_flay_all_rb
}

ruby_rgr_flog()
{
    "${2:-:}" "flog *rb"
    ruby_flog_all_rb
}

ruby_rgr_test()
{
    if ! ruby_test_identify "$1"; then
        "${2:-:}" "no test found for $1"
        return 1
    fi

    ruby_rgr_test_one "$ruby_test_identify__type" "$ruby_test_identify__file" "$2" &&
        ruby_rgr_test_all "$ruby_test_identify__type" "$2"
}

ruby_rgr_test_one()
{
    "${3:-:}" "test $2 ($1)"
    ruby_"$1" "$2"
}

ruby_rgr_test_all()
{
    "${2:-:}" "test all ($1)"
    ruby_"${1}"_all
}


########## test

RUBY_TEST_AUTOCREATE=FALSE
_RUBY_TEST_FRAMEWORKS='minitest rspec'

ruby_test_identify()
{
    ruby_test_identify__type=
    ruby_test_identify__file=

    is_ruby_file "$1" || return 1

    case "$1" in
        *_spec.rb)
            ruby_test_identify__file="$1"
            ruby_test_identify__type=rspec
            ;;
        *_test.rb)
            ruby_test_identify__file="$1"
            ruby_test_identify__type=minitest
            ;;
        spec/*.rb)
            ruby_test_identify__file="${1%\.rb}_spec.rb"
            ruby_test_identify__type=rspec
            ;;
        test/*.rb)
            ruby_test_identify__file="${1%\.rb}_test.rb"
            ruby_test_identify__type=minitest
            ;;
        # FIXME: more case ???
        app/*.rb|lib/*.rb)
            ruby_test_guess || return 1
            ruby_test_identify__file="${1%.rb}_${ruby_test_guess__dir}.rb"
            ruby_test_identify__file="${ruby_test_identify__file#*/}"
            ruby_test_identify__file="$ruby_test_guess__dir/$ruby_test_identify__file"
            ruby_test_identify__type="$ruby_test_guess__type"
            ;;
        *.rb)
            ruby_test_guess || return 1
            ruby_test_identify__file="${1%.rb}_${ruby_test_guess__dir}.rb"
            ruby_test_identify__type="$ruby_test_guess__type"
            ;;
    esac

    if $RUBY_TEST_AUTOCREATE; then
        if [ -n "$ruby_test_identify__file" ] && [ "$ruby_test_identify__file" != "$1" ]; then
            [ -r "$ruby_test_identify__file" ] ||
                touch "$ruby_test_identify__file"
        fi
    fi
}

ruby_test_guess()
{
    if ruby_has_minitest; then
        ruby_test_guess__type=minitest
        ruby_test_guess__dir="$_RUBY_MINITEST_DIR"
    elif ruby_has_rspec; then
        ruby_test_guess__type=rspec
        ruby_test_guess__dir="$_RUBY_RSPEC_DIR"
    else
        ruby_test_guess__type=ruby
        ruby_test_guess__dir="$_RUBY_MINITEST_DIR"
    fi
}


########## minitest

_RUBY_MINITEST_DIR=test
_RUBY_MINITEST_DIRS="test tests"

ruby_has_minitest()
{
    for ruby_has_minitest in $_RUBY_MINITEST_DIRS; do
        [ -d "$ruby_has_minitest" ] && return 0
    done
    return 1
}

ruby_minitest()
{
    ruby_rake test TEST="$1" ||
        ruby_ruby "$1"
}

ruby_minitest_all()
{
    ruby_rake test ||
        return 0
}


########## rspec

_RUBY_RSPEC_DIR=spec

ruby_has_rspec()
{
    [ -d "$_RUBY_RSPEC_DIR" ] && return 0
    return 1
}

ruby_rspec()
{
    which rspec 2>/dev/null >/dev/null || {
        echo >&2 "missing rspec command"
        return 0
    }
    ruby_exec rspec "$@"
}

ruby_rspec_all()
{
    ruby_rspec
}
