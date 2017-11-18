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
                   [-h|--help]
                   -- JAVA_ARGS

Examples:
  archlinux-java-run --max 8 -- -jar /path/to/application.jar
    (launches java in version 8 or below)

  archlinux-java-run --package jre -- -jar /path/to/application.jar
    (launches Oracle's java from the AUR packages jre-*)
```
