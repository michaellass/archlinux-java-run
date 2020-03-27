# Changelog

## v7
2020-03-27

* Add jdk as new testable feature. This checks for the presence of
  javac.
* Add -d|--dry-run command line argument to just output the generated
  command instead of executing it.
* Add -j|--java-home command line argument just print java location
  instead of executing java. This allows to use archlinux-java-run to
  determine a suitable value for JAVA_HOME or to run a certain version
  of executables different to java. See help output for an example.

## v6
2019-11-18

* Extend javafx feature detection to work for Java versions 9 and
  higher. If available, archlinux-java-run will automatically
  extend the module path and the list of loaded modules to make
  JavaFX available.
* Add -v|--verbose command line argument to enable verbose mode.
  archlinux-java-run will output all performed tests as well as the
  finally executed command.
* Restructure code to help performance and readability.

## v5
2019-03-23

* Detect features (for now only JavaFX) using proper tests instead of
  looking for properties files
* Include a rudamentary build system
* Improve help output

## v4
2018-04-08

* Allow requesting certain features like JavaFX. If specified,
  archlinux-java-run checks for a corresponding properties file before
  marking a JRE as eligible
* Fix check for non-empty list of eligible JREs
* Increase default upper bound for version number
* Small updates to documentation

## v3
2017-12-24

* Use exec to replace launcher by launched java process
* Fix broken fallback JVM selection in rare cases


## v2
2017-11-19

* Fix pattern matching if package is given
* Allow specifying package as a regular expression


## v1
2017-11-18

* Initial Release
