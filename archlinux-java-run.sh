#!/bin/bash

#
# Copyright (c) 2017–2026 Michael Lass
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

# This script uses `exec` on purpose to launch a suitable JRE before the end of
# the script.
# shellcheck disable=SC2093
VERSION=12
JAVADIR=###JAVADIR###

JAVAFX_MODULES=javafx.base,javafx.controls,javafx.fxml,javafx.graphics,javafx.media,javafx.swing,javafx.web

function print_usage {
  cat << EOF

USAGE:
  archlinux-java-run [-a|--min MIN] [-b|--max MAX] [-p|--package PKG]
                     [-f|--feature FEATURE] [-h|--help] [-v|--verbose]
                     [-d|--dry-run] [-j|--java-home] [-e|--exec]
                     -- <JAVA_ARGS | EXEC_CMD>

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

By default, archlinux-java-run will execute a suitable version of java
with the given JAVA_ARGS. When run with -j|--java-home, it just prints
the location of a suitable java installation so that custom commands
can be run. When run with -e|--exec, it will run EXEC_CMD in an
environment where \$JAVA_HOME and \$PATH is set so that the appropriate
Java version is used.
EOF
  print_usage
  cat << EOF
AVAILABLE FEATURES:
  javafx: Test if JVM provides support for JavaFX. For JVM versions above 8
          this will modify the module path and the list of loaded modules to
          make JavaFX available. CAUTION: Software developed for Java >8 using
          JavaFX typically provides and loads its own copy of OpenJFX. The
          feature should not be requested in this case.

  jdk:    Test if the installation is a full JDK and not just a JRE, i.e., it
          includes javac.

EXAMPLES:
  archlinux-java-run --max 8 -- -jar /path/to/application.jar
    (launches java in version 8 or below)

  archlinux-java-run --package 'jre/jre|jdk' -- -jar /path/to/application.jar
    (launches Oracle's java from one of the jre or jdk AUR packages)

  archlinux-java-run --feature 'javafx' -- -jar /path/to/application.jar
    (launches a JVM that supports JavaFX)

  JAVA_HOME=\$(archlinux-java-run --min 11 --feature jdk --java-home) \\
      && "\$JAVA_HOME"/bin/javac ...
    (launches javac from a JDK in version 11 or newer)

  archlinux-java-run --min 25 --max 25 --exec -- bash -i
    (launches interactive bash with Java 25 set as \$JAVA_HOME and as first element in \$PATH)
EOF
}

function echo_stderr {
  echo "$1" 1>&2
}

function is_in {
  [[ "$1" =~ (^| )"$2"($| ) ]]
}

function normalize_name {
  re_default="^java-([0-9]+)-(.+)\$"
  re_short="^(.+)-([0-9]+)\$"
  re_split="^([-A-Za-z]*[A-Za-z]+)-?([0-9]+)-(.+)\$"
  if [[ $1 =~ $re_default ]]; then
    echo -n "$1"
  elif [[ $1 =~ $re_short ]]; then
    echo -n "java-${BASH_REMATCH[2]}-${BASH_REMATCH[1]}"
  elif [[ $1 =~ $re_split ]]; then
    echo -n "java-${BASH_REMATCH[2]}-${BASH_REMATCH[1]}-${BASH_REMATCH[3]}"
  else
    echo_stderr "ERROR: Could not parse JRE name $1"
  fi
}

available=$(archlinux-java status | tail -n+2 | cut -d' ' -f3 | sort -rV -t- -k2 | xargs)
default=$(archlinux-java get)

if [ -z "$default" ]; then
  echo_stderr "Your Java installation is not set up correctly. Try archlinux-java fix."
  exit 1
fi

# Default boundaries for Java versions
min=-1
max=-1
for ver in $available; do
  major=$(normalize_name "$ver" | cut -d- -f2)
  if [ "$major" -gt "$max" ]; then
    max="$major"
  fi
  if [ "$major" -lt "$min" ] || [ "$min" -eq -1 ]; then
    min="$major"
  fi
done

function generate_candiates {
  local list
  local pref_package
  pref_package=$(cut -d- -f3- <<< "$(normalize_name "$default")")

  local exp
  exp="($(seq "$min" "$max"|paste -sd'|'))"
  if [ -n "$package" ]; then
    exp="^java-${exp}-(${package})\$"
  else
    exp="^java-${exp}-.*\$"
  fi

  # we want to try the user's default JRE first
  if [[ $(normalize_name "$default") =~ $exp ]]; then
    list="$default "
  fi

  local subexp
  for i in $(seq "$max" -1 "$min"); do

    # try JRE that matches the user's default package
    subexp="^java-${i}-${pref_package}\$"
    for ver in $available; do
      norm_ver=$(normalize_name "$ver")
      if [[ $norm_ver =~ $exp && $norm_ver =~ $subexp ]]; then
        if ! is_in "$list" "$ver"; then
          list="$list$ver "
        fi
      fi
    done

    # try openjdk since it is Arch's default
    subexp="^java-${i}-openjdk\$"
    for ver in $available; do
      norm_ver=$(normalize_name "$ver")
      if [[ $norm_ver =~ $exp && $norm_ver =~ $subexp ]]; then
        if ! is_in "$list" "$ver"; then
          list="$list$ver "
        fi
      fi
    done

    # try everything else
    for ver in $available; do
      norm_ver=$(normalize_name "$ver")
      if [[ $norm_ver =~ $exp ]]; then
        if ! is_in "$list" "$ver"; then
          list="$list$ver "
        fi
      fi
    done

  done

  echo "$list" | xargs
}

function exec_in_modified_env() {
  quote_args

  if [ $dryrun -eq 1 ]; then
    echo "DRY-RUN - Generated command: env JAVA_HOME=/usr/lib/jvm/${ver} PATH=/usr/lib/jvm/${ver}/bin:\$PATH exec ${quoted_java_args[*]}"
    exit 0
  fi

  if [ $verbose -eq 1 ]; then
    echo_stderr "Executing command: JAVA_HOME=/usr/lib/jvm/${ver} PATH=/usr/lib/jvm/${ver}/bin:\$PATH exec ${quoted_java_args[*]}"
  fi

  export JAVA_HOME="/usr/lib/jvm/${ver}"
  export PATH="/usr/lib/jvm/${ver}/bin:$PATH"
  exec "${java_args[@]}"
}

function test_javafx_support() {
  if [ "$major" -lt 9 ]; then
    testcmd="/usr/lib/jvm/${ver}/bin/java -jar ${JAVADIR}/archlinux-java-run/TestJavaFX.jar"
  else
    mpath=$(eval echo "/usr/lib/jvm/{${ver},java-${major}-openjfx}/lib/{javafx.base,javafx.controls,javafx.fxml,javafx.graphics,javafx.media,javafx.swing,javafx.web,javafx-swt}.jar" | tr ' ' :)
    testcmd="/usr/lib/jvm/${ver}/bin/java --module-path ${mpath} --add-modules ALL-MODULE-PATH -jar ${JAVADIR}/archlinux-java-run/TestJavaFX.jar"
  fi
  if [ "$verbose" -eq 1 ]; then
    echo_stderr "Testing JavaFX support: $testcmd"
  fi
  $testcmd
}

function test_jdk_support() {
  test -x /usr/lib/jvm/"$ver"/bin/javac
}

function extend_java_args() {
  local updated=0
  for i in "${!java_args[@]}"; do
    case "${java_args[i]}" in
    --"$1"=*)
      java_args[i]="${java_args[i]}$3$2"
      updated=1
      ;;
    --"$1")
      java_args[i+1]="${java_args[i+1]}$3$2"
      updated=1
      ;;
    esac
  done
  if [ $updated -eq 0 ]; then
    java_args=("--$1=$2" "${java_args[@]}")
  fi
}

function quote_args() {
  for arg in "${java_args[@]}"; do
    if [[ $arg =~ " " ]]; then
      quoted_java_args+=("${arg@Q}")
    else
      quoted_java_args+=("${arg}")
    fi
  done
}

args=( )
for arg; do
  case "$arg" in
    --min)       args+=( -a ) ;;
    --max)       args+=( -b ) ;;
    --help)      args+=( -h ) ;;
    --exec)      args+=( -e ) ;;
    --package)   args+=( -p ) ;;
    --feature)   args+=( -f ) ;;
    --verbose)   args+=( -v ) ;;
    --dry-run)   args+=( -d ) ;;
    --java-home) args+=( -j ) ;;
    *)           args+=( "$arg" ) ;;
  esac
done
set -- "${args[@]}"
features=( )
java_args=( )
quoted_java_args=( )
verbose=0
exec=0
dryrun=0
javahome=0
args_parsed=0
while :; do
  if [ $args_parsed -eq 0 ]; then
    case "$1" in
    -a) case "$2" in
        ''|*[!0-9]*)  echo_stderr "-a|--min expects an integer argument"
                      exit 1
                      ;;
        *)  min=$2
            shift
            ;;
        esac
        ;;
    -b) case "$2" in
        ''|*[!0-9]*)  echo_stderr "-b|--max expects an integer argument"
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
        ''|-*|*' '*)  echo_stderr "-p|--package expects exactly one argument"
                      exit 1
                      ;;
        *)  package=$2
            shift
            ;;
        esac
        ;;
    -f) case "$2" in
        ''|-*|*' '*)  echo_stderr "-f|--feature expects exactly one argument"
                      exit 1
                      ;;
        *)  features+=( "$2" )
            shift
            ;;
        esac
        ;;
    -v) verbose=1
        ;;
    -d) dryrun=1
        ;;
    -j) javahome=1
        ;;
    -e) exec=1
        ;;
    --) args_parsed=1
        ;;
    '') break
        ;;
    *)  echo_stderr "Unknown argument: $1"
        print_usage 1>&2
        exit 1
        ;;
    esac
  else
    [ "$1" == '' ] && break
    java_args+=("$1")
  fi
  shift
done

candidates=$(generate_candiates)

for ver in $candidates; do

  major=$(normalize_name "$ver" | cut -d- -f2)

  # Test for each of the required features
  for ft in "${features[@]}"; do
    case "$ft" in
    jdk)
      if ! test_jdk_support; then
        continue 2
      fi
      ;;
    javafx)
      if ! test_javafx_support; then
        continue 2
      fi
      ;;
    *)
      echo_stderr "Ignoring request for unknown feature $ft"
      ;;
    esac
  done

  if [ $javahome -eq 1 ]; then
    echo "/usr/lib/jvm/${ver}"
    exit 0
  fi

  if [ $exec -eq 1 ]; then
    exec_in_modified_env
  fi

  for ft in "${features[@]}"; do
    case "$ft" in
    javafx)
      if [ "$major" -gt 8 ]; then
        echo_stderr "Modifying java arguments to support system installation of JavaFX"
        additional_mpath=$(eval echo "/usr/lib/jvm/{${ver},java-${major}-openjfx}/lib/{javafx.base,javafx.controls,javafx.fxml,javafx.graphics,javafx.media,javafx.swing,javafx.web,javafx-swt}.jar" | tr ' ' :)
        extend_java_args module-path "$additional_mpath" ':'
        extend_java_args add-modules "$JAVAFX_MODULES" ','
      fi
      ;;
    esac
  done

  quote_args

  if [ $dryrun -eq 1 ]; then
    echo "DRY-RUN - Generated command: /usr/lib/jvm/${ver}/bin/java ${quoted_java_args[*]}"
    exit 0
  fi

  if [ $verbose -eq 1 ]; then
    echo_stderr "Executing command: /usr/lib/jvm/${ver}/bin/java ${quoted_java_args[*]}"
  fi

  exec /usr/lib/jvm/"$ver"/bin/java "${java_args[@]}"

done

echo_stderr "No suitable JVM found."
echo_stderr "Available:         $available"
echo_stderr "Default:           $default"
echo_stderr "Min. required:     $min"
echo_stderr "Max. required:     $max"
echo_stderr "Package required:  $package"
echo_stderr "Candidates:        $candidates"
echo_stderr "Features required: ${features[*]}"
exit 1
