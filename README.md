# archlinux-java-run
Java Application Launcher for Arch Linux

archlinux-java-run is a helper script used to launch Java applications
that have specific demands on version or provider of the used JVM.
Options can be arbitrarily combined and archlinux-java-run will try to
find a suitable version. If the user's default JVM is eligible, it will
be used. Otherwise, if multiple eligible versions are installed, the
newest Java generation is used. If multiple packages are available for
this version, the one corresponding to the user's default JVM is used.

## Usage
```
  archlinux-java-run [-a|--min MIN] [-b|--max MAX] [-p|--package PKG]
                     [-f|--feature FEATURE] [-h|--help] [-v|--verbose]
                     [-d|--dry-run]
                     -- JAVA_ARGS
```

## Available features

* javafx: Test if JVM provides support for JavaFX. For JVM versions above 8
  this will modify the module path and the list of loaded modules to make
  JavaFX available. **CAUTION**: Software developed for Java >8 using JavaFX
  typically provides and loads its own copy of OpenJFX. The feature should not
  be requested in this case.

* jdk: Test if the installation is a full JDK and not just a JRE, i.e., it
  includes javac.

## Examples
* Launch java in version 8 or below:
  `archlinux-java-run --max 8 -- -jar /path/to/application.jar`

* Launch Oracle's java from one of the jre or jdk AUR packages:
  `archlinux-java-run --package 'jre/jre|jdk' -- -jar /path/to/application.jar`

* Launch a JVM that supports JavaFX:
  `archlinux-java-run --feature 'javafx' -- -jar /path/to/application.jar`
