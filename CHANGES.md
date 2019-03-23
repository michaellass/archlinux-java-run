# Changelog

## v5
WORK IN PROGRESS

* Detect features (for now only JavaFX) using proper tests instead of
  looking for properties files
* Include a rudamentary build system

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
