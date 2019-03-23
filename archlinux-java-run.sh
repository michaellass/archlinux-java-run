#!/bin/bash

#
# (c) 2017, 2018, 2019 Michael Lass
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
max=20

JAVADIR=###JAVADIR###

function print_usage {
  cat << EOF

archlinux-java-run [-a|--min MIN] [-b|--max MAX] [-p|--package PKG]
                   [-f|--feature FEATURE] [-h|--help]
                   -- JAVA_ARGS

EOF
}

function print_help {
  print_usage
  cat << EOF
Examples:
  archlinux-java-run --max 8 -- -jar /path/to/application.jar
    (launches java in version 8 or below)

  archlinux-java-run --package 'jre/jre|jdk' -- -jar /path/to/application.jar
    (launches Oracle's java from one of the jre or jdk AUR packages)

  archlinux-java-run --feature 'javafx' -- -jar /path/to/application.jar
    (launches java which contains a javafx implementation)

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
    --feature) args+=( -f ) ;;
    *)         args+=( "$arg" ) ;;
  esac
done
set -- "${args[@]}"
features=( )
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
        ''|-*|*' '*)  echo "-p|--package expects exactly one argument"
                      exit 1
                      ;;
        *)  package=$2
            shift
            ;;
        esac
        ;;
    -f) case "$2" in
        ''|-*|*' '*)  echo "-f|--feature expects exactly one argument"
                      exit 1
                      ;;
        *)  features+=( "$2" )
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

if [ -z "$default" ]; then
  echo "Your Java installation is not set up correctly. Try archlinux-java fix."
  exit 1
fi

exp="($(seq $min $max|paste -sd'|'))"
if [ -n "$package" ]; then
  exp="^java-${exp}-($package)\$"
else
  exp="^java-${exp}-.*\$"
fi


eligible=( )
for ver in $available; do
  if [[ $ver =~ $exp ]]; then

    # Check for each of the required features by looking for a
    # corresponding properties file
    for ft in "${features[@]}"; do
      ls /usr/lib/jvm/${ver%/jre}/jre/lib/${ft}.properties >/dev/null \
                                                          2>/dev/null
      if [ $? -ne 0 ]; then
        continue 2
      fi
    done

    eligible+=( "$ver" )
  fi
done

if [ "${#eligible[@]}" -eq 0 ]; then
  echo "No suitable JVM found."
  echo "Available:         "$available
  echo "Min. required:     "$min
  echo "Max. required:     "$max
  echo "Package required:  "$package
  echo "Features required: "${features[@]}
  exit 1
fi

# If default JRE is suitable, bypass any remaining logic
if [[ " ${eligible[@]} " =~ " $default " ]]; then
  exec /usr/lib/jvm/$default/bin/java "$@"
fi

candidates=( )
newest=0
for ver in "${eligible[@]}"; do
  jvm_ver=$(cut -d- -f2 <<< "$ver")
  if [ $newest -eq 0 ]; then
    newest=$jvm_ver
  elif [ $newest -gt $jvm_ver ]; then
    break
  fi
  candidates+=( "$ver" )
done

pref_package=$(cut -d- -f3- <<< "$default")
pref_version="java-$newest-${pref_package}"

if [[ " ${candidates[@]} " =~ " ${pref_version} " ]]; then
  exec /usr/lib/jvm/${pref_version}/bin/java "$@"
elif [[ " ${candidates[@]} " =~ " java-$newest-openjdk " ]]; then
  exec /usr/lib/jvm/java-$newest-openjdk/bin/java "$@"
else
  exec /usr/lib/jvm/$candidates/bin/java "$@"
fi
