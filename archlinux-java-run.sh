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

VERSION=5
JAVADIR=###JAVADIR###

JAVAFX_MODULES=javafx.base,javafx.controls,javafx.fxml,javafx.graphics,javafx.media,javafx.swing,javafx.web

function print_usage {
  cat << EOF

USAGE:
  archlinux-java-run [-a|--min MIN] [-b|--max MAX] [-p|--package PKG]
                     [-f|--feature FEATURE] [-h|--help] [-v|--verbose]
                     -- JAVA_ARGS

EOF
}

function print_help {
  cat << EOF

archlinux-java-run, Version v$VERSION

archlinux-java-run is a helper script used to launch Java applications
that have specific demands on version or provider of the used JVM.
Options can be arbitrarily combined and archlinux-java-run will try to
find a suitable version. If the user's default JVM is eligible, it will
be used. Otherwise, if multiple eligible versions are installed, the
newest Java generation is used. If multiple packages are available for
this version, the one corresponding to the user's default JVM is used.
EOF
  print_usage
  cat << EOF
AVAILABLE FEATURES:
  javafx: Test if JVM provides support for JavaFX.

EXAMPLES:
  archlinux-java-run --max 8 -- -jar /path/to/application.jar
    (launches java in version 8 or below)

  archlinux-java-run --package 'jre/jre|jdk' -- -jar /path/to/application.jar
    (launches Oracle's java from one of the jre or jdk AUR packages)

  archlinux-java-run --feature 'javafx' -- -jar /path/to/application.jar
    (launches a JVM that supports JavaFX)

EOF
}

function generate_candiates {
  local list=" "
  local pref_package=$(cut -d- -f3- <<< "$default")

  local exp="($(seq $min $max|paste -sd'|'))"
  if [ -n "$package" ]; then
    exp="^java-${exp}-(${package})\$"
  else
    exp="^java-${exp}-.*\$"
  fi

  # we want to try the user's default JRE first
  if [[ $default =~ $exp ]]; then
    list="$list$default "
  fi

  local subexp=""
  for i in $(seq $max -1 $min); do

    # try JRE that matches the user's default package
    subexp="^java-${i}-${pref_package}\$"
    for ver in $available; do
      if [[ $ver =~ $exp && $ver =~ $subexp ]]; then
        if [[ ! "$list" =~ " $ver " ]]; then
          list="$list$ver "
        fi
      fi
    done

    # try openjdk
    subexp="^java-${i}-openjdk\$"
    for ver in $available; do
      if [[ $ver =~ $exp && $ver =~ $subexp ]]; then
        if [[ ! "$list" =~ " $ver " ]]; then
          list="$list$ver "
        fi
      fi
    done

    # try everything else
    subexp="^java-${i}-\S*$"
    for ver in $available; do
      if [[ $ver =~ $exp && $ver =~ $subexp ]]; then
        if [[ ! "$list" =~ " $ver " ]]; then
          list="$list$ver "
        fi
      fi
    done

  done

  echo $list
}

function test_javafx_support() {
  if [ $major -lt 9 ]; then
    testcmd="/usr/lib/jvm/${ver}/bin/java -jar ${JAVADIR}/archlinux-java-run/TestJavaFX.jar"
  else
    mpath=$(eval echo "/usr/lib/jvm/{${ver},java-${major}-openjfx}/lib/{javafx.base,javafx.controls,javafx.fxml,javafx.graphics,javafx.media,javafx.swing,javafx.web,javafx-swt}.jar" | tr ' ' :)
    testcmd="/usr/lib/jvm/${ver}/bin/java --module-path ${mpath} --add-modules ALL-MODULE-PATH -jar ${JAVADIR}/archlinux-java-run/TestJavaFX.jar"
  fi
  if [ $verbose -eq 1 ]; then
    echo "Testing JavaFX support: $testcmd"
  fi
  $testcmd
}

function extend_java_args() {
  local updated=0
  for i in "${!java_args[@]}"; do
    case "${java_args[$i]}" in
    --$1=*)
      java_args[$i]="${java_args[$i]}$3$2"
      updated=1
      ;;
    --$1)
      java_args[$((i+1))]="${java_args[$((i+1))]}$3$2"
      updated=1
      ;;
    esac
  done
  if [ $updated -eq 0 ]; then
    java_args=("--$1=$2" "${java_args[@]}")
  fi
}

args=( )
for arg; do
  case "$arg" in
    --min)     args+=( -a ) ;;
    --max)     args+=( -b ) ;;
    --help)    args+=( -h ) ;;
    --package) args+=( -p ) ;;
    --feature) args+=( -f ) ;;
    --verbose) args+=( -v ) ;;
    *)         args+=( "$arg" ) ;;
  esac
done
set -- "${args[@]}"
features=( )
verbose=0
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
    -v) verbose=1
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

read -r -a java_args <<< "$@"

available=$(archlinux-java status | grep -Eo 'java\S*' | sort -rV)
default=$(archlinux-java get)

if [ -z "$default" ]; then
  echo "Your Java installation is not set up correctly. Try archlinux-java fix."
  exit 1
fi

candidates=$(generate_candiates)

for ver in $candidates; do

  major=$(cut -d- -f2 <<< "$ver")

  # Test for each of the required features
  for ft in "${features[@]}"; do
    case "$ft" in
    javafx)
      test_javafx_support
      if [ $? -ne 0 ]; then
        continue 2
      fi
      ;;
    *)
      echo "Ignoring request for unknown feature $ft"
      ;;
    esac
  done

  for ft in "${features[@]}"; do
    case "$ft" in
    javafx)
      if [ $major -gt 8 ]; then
        echo "Modifying java arguments to support system installation of JavaFX"
        additional_mpath=$(eval echo "/usr/lib/jvm/{${ver},java-${major}-openjfx}/lib/{javafx.base,javafx.controls,javafx.fxml,javafx.graphics,javafx.media,javafx.swing,javafx.web,javafx-swt}.jar" | tr ' ' :)
        extend_java_args module-path ${additional_mpath} ':'
        extend_java_args add-modules ${JAVAFX_MODULES} ','
      fi
      ;;
    esac
  done

  if [ $verbose -eq 1 ]; then
    echo "Executing command: /usr/lib/jvm/${ver}/bin/java ${java_args[@]}"
  fi

  exec /usr/lib/jvm/${ver}/bin/java "${java_args[@]}"

done

echo "No suitable JVM found."
echo "Available:         "$available
echo "Default:           "$default
echo "Min. required:     "$min
echo "Max. required:     "$max
echo "Package required:  "$package
echo "Candidates:        "$candidates
echo "Features required: "${features[@]}
exit 1
