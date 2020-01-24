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


########## python

pip_exec()
{
    which pip 2>/dev/null >/dev/null || {
        echo >&2 "missing pip command"
        return 1
    }
    pip "$@"
}

pip_requirements()
{
    pip_exec install -r "$1"
}

python_exec()
{
    which python 2>/dev/null >/dev/null || {
        echo >&2 "missing python command"
        return 1
    }
    python "$@"
}

python_flake8()
{
    which flake8 2>/dev/null >/dev/null || {
        echo >&2 "missing flake8 command"
        return 1
    }
    flake8 "$@"
}

python_pylint()
{
    which pylint 2>/dev/null >/dev/null || {
        echo >&2 "missing pylint command"
        return 1
    }
    pylint "$@"
}

python_black()
{
    which black 2>/dev/null >/dev/null || {
        echo >&2 "missing black command"
        return 1
    }
    black "$@"
}

python_pytest()
{
    which pytest 2>/dev/null >/dev/null || {
        echo >&2 "missing pytest command"
        return 1
    }
    pytest "$@"
}


########## rgr

DEVEL_LANG="${DEVEL_LANG:+$DEVEL_LANG }python requirements"

PYTHON_LINTER="${PYTHON_LINTER:-flake8}"
PYTHON_AUTOLINTER="${PYTHON_AUTOLINTER:-black}"

is_python_file()
{
    [ -d "$1" ] && return 1

    case "$1" in
        *.py)
            return 0
    esac
    return 1
}

is_requirements_file()
{
    [ -d "$1" ] && return 1

    case "$1" in
        requirements.txt|requirements*.txt)
            return 0
    esac
    return 1
}

requirements_rgr()
{
    pip_rgr_install "$@"
}

pip_rgr_install()
{
    "${2:-:}" "pip install -r $1"
    pip_requirements "$1"
}

python_rgr()
{
    python_rgr_test "$@" &&
        python_rgr_lint "$@"
}

python_rgr_lint()
{
    python_rgr_"$PYTHON_LINTER" "$@"
    python_rgr_lint__status=$?

    if [ $python_rgr_lint__status -ne 0 ] && $RGR_AUTO; then
        python_rgr_"$PYTHON_AUTOLINTER" "$@"
        python_rgr_"$PYTHON_LINTER" "$@"
        python_rgr_lint__status=$?
    fi
    return $python_rgr_lint__status
}

python_rgr_pylint()
{
    "${2:-:}"  "pylint $1"
    python_pylint "$1"
}

python_rgr_flake8()
{
    "${2:-:}"  "flake8 $1"
    python_flake8 "$1"
}

python_rgr_black()
{
    "${2:-:}"  "black $1"
    python_black "$1"
}

python_rgr_test()
{
    if ! python_test_identify "$1"; then
        "${2:-:}" "no test found for $1"
        return 1
    fi

    python_rgr_test_one "$python_test_identify__dir" "$python_test_identify__file" "$2" &&
        python_rgr_test_all "$python_test_identify__type" "$2"
}

python_rgr_test_one()
{
    "${3:-:}" "test $2 ($1)"
    python_"$1" "$2"
}

python_rgr_test_all()
{
    "${2:-:}" "test all ($1)"
    python_"${1}"
}


# ########## test

# RUBY_TEST_AUTOCREATE=FALSE
# _RUBY_TEST_FRAMEWORKS='minitest rspec'

# ruby_test_identify()
# {
#     ruby_test_identify__type=
#     ruby_test_identify__file=

#     is_ruby_file "$1" || return 1

#     case "$1" in
#         *_spec.rb)
#             ruby_test_identify__file="$1"
#             ruby_test_identify__type=rspec
#             ;;
#         *_test.rb)
#             ruby_test_identify__file="$1"
#             ruby_test_identify__type=minitest
#             ;;
#         spec/*.rb)
#             ruby_test_identify__file="${1%\.rb}_spec.rb"
#             ruby_test_identify__type=rspec
#             ;;
#         test/*.rb)
#             ruby_test_identify__file="${1%\.rb}_test.rb"
#             ruby_test_identify__type=minitest
#             ;;
#         # FIXME: more case ???
#         app/*.rb|lib/*.rb)
#             ruby_test_guess || return 1
#             ruby_test_identify__file="${1%.rb}_${ruby_test_guess__dir}.rb"
#             ruby_test_identify__file="${ruby_test_identify__file#*/}"
#             ruby_test_identify__file="$ruby_test_guess__dir/$ruby_test_identify__file"
#             ruby_test_identify__type="$ruby_test_guess__type"
#             ;;
#         *.rb)
#             ruby_test_guess || return 1
#             ruby_test_identify__file="${1%.rb}_${ruby_test_guess__dir}.rb"
#             ruby_test_identify__type="$ruby_test_guess__type"
#             ;;
#     esac

#     if $RUBY_TEST_AUTOCREATE; then
#         if [ -n "$ruby_test_identify__file" ] && [ "$ruby_test_identify__file" != "$1" ]; then
#             [ -r "$ruby_test_identify__file" ] ||
#                 touch "$ruby_test_identify__file"
#         fi
#     fi
# }

# ruby_test_guess()
# {
#     if ruby_has_minitest; then
#         ruby_test_guess__type=minitest
#         ruby_test_guess__dir="$_RUBY_MINITEST_DIR"
#     elif ruby_has_rspec; then
#         ruby_test_guess__type=rspec
#         ruby_test_guess__dir="$_RUBY_RSPEC_DIR"
#     else
#         ruby_test_guess__type=ruby
#         ruby_test_guess__dir="$_RUBY_MINITEST_DIR"
#     fi
# }


# ########## minitest

# _RUBY_MINITEST_DIR=test
# _RUBY_MINITEST_DIRS="test tests"

# ruby_has_minitest()
# {
#     for ruby_has_minitest in $_RUBY_MINITEST_DIRS; do
#         [ -d "$ruby_has_minitest" ] && return 0
#     done
#     return 1
# }

# ruby_minitest()
# {
#     ruby_rake test TEST="$1" ||
#         ruby_ruby "$1"
# }

# ruby_minitest_all()
# {
#     ruby_rake test ||
#         return 0
# }


# ########## rspec

# _RUBY_RSPEC_DIR=spec

# ruby_has_rspec()
# {
#     [ -d "$_RUBY_RSPEC_DIR" ] && return 0
#     return 1
# }

# ruby_rspec()
# {
#     which rspec 2>/dev/null >/dev/null || {
#         echo >&2 "missing rspec command"
#         return 0
#     }
#     ruby_exec rspec "$@"
# }

# ruby_rspec_all()
# {
#     ruby_rspec
# }
