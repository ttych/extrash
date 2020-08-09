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

RUBY_RGR_RUBOCOP_AUTO='-a'


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
    ruby_exec rubocop "$@"
}

ruby_reek()
{
    which reek 2>/dev/null >/dev/null || {
        echo >&2 "missing reek command"
        return 0
    }
    ruby_exec reek "$@"
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
    ruby_rgr_rubocop__flag=
    if $RGR_AUTO; then
        ruby_rgr_rubocop__flag="$RUBY_RGR_RUBOCOP_AUTO"
    fi
    ruby_rubocop -f fu $ruby_rgr_rubocop__flag "$1"
}

ruby_rgr_reek()
{
    "${2:-:}"  "reek $1"
    ruby_reek "$1"
}

ruby_rgr_flay()
{
    "${2:-:}" "flay *rb"
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

    ruby_rgr_test__frameworks=
    for ruby_rgr_test__t in $ruby_test_identify; do
        ruby_rgr_test__framework="${ruby_rgr_test__t%%:*}"
        ruby_rgr_test__test_file="${ruby_rgr_test__t#$ruby_rgr_test__framework}"
        ruby_rgr_test__test_file="${ruby_rgr_test__test_file#:}"

        case $ruby_rgr_test__frameworks in
            *"$ruby_rgr_test__framework"*) ;;
            *)
                ruby_rgr_test__frameworks="${ruby_rgr_test__frameworks:+$ruby_rgr_test__frameworks }$ruby_rgr_test__framework"
                ;;
        esac

        if [ -n "$ruby_rgr_test__test_file" ]; then
            ruby_rgr_test_one "$ruby_rgr_test__framework" "$ruby_rgr_test__test_file" "$2" || return 1
        fi
    done

    for ruby_rgr_test__framework in $ruby_rgr_test__frameworks; do
        ruby_rgr_test_all "$ruby_rgr_test__framework" "$2" || return 1
    done
}

ruby_rgr_test_one()
{
    [ "$2" = "NO_ONE" ] && return 0

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
    ruby_test_identify=

    is_ruby_file "$1" || return 1

    ruby_test_frameworks
    ruby_test_identify__frameworks="$ruby_test_frameworks"

    case "$1" in
        spec/spec_helper.rb|spec/rails_helper.rb)
            ruby_test_identify__frameworks=rspec
            ;;
        test/test_helper.rb|tests/test_helper.rb)
            ruby_test_identify__frameworks=minitest
            ;;
        config/*)
            ;;
        db/*)
            ;;
        *_spec.rb)
            ruby_test_identify="rspec:$1"
            ruby_test_identify__frameworks=rspec
            ;;
        spec/*.rb)
            ruby_test_identify="rspec:${1%\.rb}_spec.rb"
            ruby_test_identify__frameworks=rspec
            ;;
        *_test.rb)
            ruby_test_identify="minitest:$1"
            ruby_test_identify__frameworks=minitest
            ;;
        test/*.rb|tests/*.rb)
            ruby_test_identify="minitest:${1%\.rb}_test.rb"
            ruby_test_identify__frameworks=minitest
            ;;
        *.rb)
            ruby_test_identify__should=
            for ruby_test_identify__framework in $ruby_test_frameworks; do
                ruby_${ruby_test_identify__framework}_identify_test "$1"
                ruby_test_identify__status=$?
                eval ruby_test_identify__found="\"$ruby_test_identify__framework:\$ruby_${ruby_test_identify__framework}_identify_test\""

                if [ $ruby_test_identify__status -eq 0 ]; then
                    ruby_test_identify="${ruby_test_identify:+$ruby_test_identify }$ruby_test_identify__found"
                else
                    [ -z "$ruby_test_identify__bkp" ] && ruby_test_identify__bkp="$ruby_test_identify__found"
                fi
            done

            [ -z "$ruby_test_identify" ] && ruby_test_identify="$ruby_test_identify__bkp"
            ;;
    esac

    # if $RUBY_TEST_AUTOCREATE; then
    #     if [ -n "$ruby_test_identify__file" ] && [ "$ruby_test_identify__file" != "$1" ]; then
    #         [ -r "$ruby_test_identify__file" ] ||
    #             touch "$ruby_test_identify__file"
    #     fi
    # fi

    ruby_test_identify="${ruby_test_identify:+$ruby_test_identify }$ruby_test_identify__frameworks"
}

ruby_test_frameworks()
{
    ruby_test_frameworks=

    if ruby_has_minitest; then
        ruby_test_frameworks="${ruby_test_frameworks:+$ruby_test_frameworks }minitest"
    fi
    if ruby_has_rspec; then
        ruby_test_frameworks="${ruby_test_frameworks:+$ruby_test_frameworks }rspec"
    fi
    if [ -z "$ruby_test_frameworks" ]; then
        ruby_test_frameworks=ruby
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

ruby_minitest_identify_test()
{
    ruby_minitest_identify_test=

    ruby_minitest_identify_test__file="$1"
    ruby_minitest_identify_test__test_file="${ruby_minitest_identify_test__file%\.rb}_test.rb"

    ruby_minitest_identify_test__test_file_pre="${ruby_minitest_identify_test__test_file%%/*}"
    ruby_minitest_identify_test__test_file_sub="${ruby_minitest_identify_test__test_file#$ruby_minitest_identify_test__test_file_pre/}"

    # check minitest dir
    for ruby_minitest_identify_test_d in $_RUBY_MINITEST_DIRS; do
        [ -d "$ruby_minitest_identify_test_d" ] || continue

        ruby_minitest_identify_test="$ruby_minitest_identify_test_d/$ruby_minitest_identify_test__test_file"
        [ -r "$ruby_minitest_identify_test" ] && return 0

        ruby_minitest_identify_test="$ruby_minitest_identify_test_d/$ruby_minitest_identify_test__test_file_sub"
        [ -r "$ruby_minitest_identify_test" ] && return 0
    done

    # along
    ruby_minitest_identify_test="$ruby_minitest_identify_test__test_file"
    [ -r "$ruby_minitest_identify_test" ] && return 0

    # should
    ruby_minitest_identify_test="$_RUBY_MINITEST_DIR/$ruby_minitest_identify_test__test_file_sub"
    [ -r "$ruby_minitest_identify_test" ] && return 0

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

ruby_rspec_identify_test()
{
    ruby_rspec_identify_test=

    ruby_rspec_identify_test__file="$1"
    ruby_rspec_identify_test__test_file="${ruby_rspec_identify_test__file%\.rb}_spec.rb"

    ruby_rspec_identify_test__test_file_pre="${ruby_rspec_identify_test__test_file%%/*}"
    ruby_rspec_identify_test__test_file_sub="${ruby_rspec_identify_test__test_file#$ruby_rspec_identify_test__test_file_pre/}"

    # check rspec dir
    if [ -d "$_RUBY_RSPEC_DIR" ]; then
        ruby_rspec_identify_test="$_RUBY_RSPEC_DIR/$ruby_rspec_identify_test__test_file"
        [ -r "$ruby_rspec_identify_test" ] && return 0

        ruby_rspec_identify_test="$_RUBY_RSPEC_DIR/$ruby_rspec_identify_test__test_file_sub"
        [ -r "$ruby_rspec_identify_test" ] && return 0
    fi

    # along
    ruby_rspec_identify_test="$ruby_rspec_identify_test__test_file"
    [ -r "$ruby_rspec_identify_test" ] && return 0

    # should
    ruby_rspec_identify_test="$_RUBY_RSPEC_DIR/$ruby_rspec_identify_test__test_file_sub"
    [ -r "$ruby_rspec_identify_test" ] && return 0

    return 1
}

ruby_rspec()
{
    if [ -x 'bin/rspec' ]; then
        ./bin/rspec "$@"
        return "$?"
    fi

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


########## rails

rails_bootstrap()
{
    # 0. clean Gemfile
    if [ -r "Gemfile" ]; then
        if egrep "^gem ['\"](bootstrap|jquery-rails)['\"]" Gemfile >/dev/null; then
            egrep -v "^gem ['\"](bootstrap|jquery-rails)['\"]" Gemfile > Gemfile.new &&
                mv Gemfile.new Gemfile

            bundle
        fi
    fi

    # 1. yarn install
    yarn add bootstrap jquery popper.js

    # 2. config/webpack/environment.js
    if ! grep jQuery config/webpack/environment.js >/dev/null; then
        ruby -plne "print \"const webpack = require('webpack')
environment.plugins.append(
    'Provide',
    new webpack.ProvidePlugin({
        \$: 'jquery',
        jQuery: 'jquery',
        Popper: ['popper.js', 'default']
    })
)
\" if /module.exports = environment/" config/webpack/environment.js > config/webpack/environment.js.new &&
            mv config/webpack/environment.js.new config/webpack/environment.js
    fi

    # 3. app/javascript/packs/application.js
    grep '^require ("bootstrap")' app/javascript/packs/application.js >/dev/null ||
        echo 'require ("bootstrap")' >> app/javascript/packs/application.js

    # 4. app/assets/stylesheets/application.css
    if [ ! -r app/assets/stylesheets/application.scss ]; then
        if [ -r app/assets/stylesheets/application.css ]; then
            mv app/assets/stylesheets/application.css app/assets/stylesheets/application.scss
        else
            touch app/assets/stylesheets/application.scss
        fi
    fi
    grep '^@import "bootstrap/scss/bootstrap";' app/assets/stylesheets/application.scss >/dev/null ||
        echo '@import "bootstrap/scss/bootstrap";' >> app/assets/stylesheets/application.scss
}
