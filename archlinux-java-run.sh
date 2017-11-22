#!/bin/bash

#
# (c) 2017 Michael Lass
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# Default boundaries for Java versions
min=6
max=10

function print_usage {
  cat << EOF

archlinux-java-run [-a|--min MIN] [-b|--max MAX] [-p|--package PKG]
                   [-h|--help]
                   -- JAVA_ARGS

EOF
}

function print_help {
  print_usage
  cat << EOF
Examples:
  archlinux-java-run --max 8 -- -jar /path/to/application.jar
    (launches java in version 8 or below)

  archlinux-java-run --package 'jre|jdk' -- -jar /path/to/application.jar
    (launches Oracle's java from one of the jre-* or jdk-* AUR packages)

archlinux-java-run is a helper script used to launch Java applications
that have specific demands on version or provider of the used JVM.
Options can be arbitrarily combined and archlinux-java-run will try to
find a suitable version. If the user's default JVM is eligible, it will
be used. Otherwise, if multiple eligible versions are installed, the
newest Java generation is used. If multiple packages are available for
this version, the one corresponding to the user's default JVM is used.

EOF
}

args=( )
for arg; do
  case "$arg" in
    --min)     args+=( -a ) ;;
    --max)     args+=( -b ) ;;
    --help)    args+=( -h ) ;;
    --package) args+=( -p ) ;;
    *)         args+=( "$arg" ) ;;
  esac
done
set -- "${args[@]}"
while :; do
    case "$1" in
    -a) case "$2" in
        ''|*[!0-9]*)  echo "-a|--min expects an integer argument"
                      exit 1
                      ;;
        *)  min=$2
            shift
            ;;
        esac
        ;;
    -b) case "$2" in
        ''|*[!0-9]*)  echo "-b|--max expects an integer argument"
                      exit 1
                      ;;
        *)  max=$2
            shift
            ;;
        esac
        ;;
    -h) print_help
        exit 0
        ;;
    -p) case "$2" in
        ''|-*|*' '*)  echo "-p|--package expects a single literal argument"
                      exit 1
                      ;;
        *)  package=$2
            shift
            ;;
        esac
        ;;
    --) shift
        break
        ;;
    '') break
        ;;
    *)  echo "Unknown argument: $1"
        print_usage
        exit 1
        ;;
    esac
    shift
done

available=$(archlinux-java status | grep -Eo 'java\S*' | sort -rV)
default=$(archlinux-java get)

if [ "x$default" == "x" ]; then
  echo "Your Java installation is not set up correctly. Try archlinux-java fix."
  exit 1
fi

exp="($(seq $min $max|paste -sd'|'))"
if [ "x$package" != "x" ]; then
  exp="^java-${exp}-($package)\$"
else
  exp="^java-${exp}-.*\$"
fi

if [[ $default =~ $exp ]]; then
  exec /usr/lib/jvm/$default/bin/java "$@"
fi

eligible=( )
newest=0
for ver in $available; do
  if [[ $ver =~ $exp ]]; then
    jvm_ver=$(cut -d- -f2 <<< "$ver")
    if [ $newest -eq 0 ]; then
      newest=$jvm_ver
    elif [ $newest -gt $jvm_ver ]; then
      break
    fi
    eligible+=( $ver )
  fi
done

if [ "x${eligible[@]}" == "x" ]; then
  echo "No suitable JVM found."
  echo "Available:        "$available
  echo "Min. required:    $min"
  echo "Max. required:    $max"
  [ "x$package" != "x" ] && echo "Package required: $package"
  exit 1
fi

pref_package=$(cut -d- -f3- <<< "$default")
pref_version="java-$newest-${pref_package}"

if [[ " ${eligible[@]} " =~ " ${pref_version} " ]]; then
  exec /usr/lib/jvm/${pref_version}/bin/java "$@"
elif [[ " ${eligible[@]} " =~ " java-$newest-openjdk " ]]; then
  exec /usr/lib/jvm/java-$newest-openjdk/bin/java "$@"
else
  exec /usr/lib/jvm/$eligible/bin/java "$@"
fi
