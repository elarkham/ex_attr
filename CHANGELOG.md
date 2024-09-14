# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.1] - 2024-09-14

### Fixed 
- Fix EPERM error when working on symlinks

## [2.0.0] - 2024-06-11

### Fixed 
- Fixed `ExAttr.dump!/1` returning `{:ok, map}` instead of `map` 

### Changed 
- Errors are now returned as POSIX atoms when possible to align with the error semantics of the `File`/`:file` modules and to make pattern matching easier

## [1.0.1] - 2024-06-11

### Added 
- This Changelog 

### Fixed 
- Running `ExAttr.set/3` with a `nil` value will no longer generate an error when performed on a field that does not exist

## [1.0.0] - 2024-06-10

### Added
- Initial Release 

[unreleased]: https://github.com/elarkham/ex_attr/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/elarkham/ex_attr/releases/tag/v2.0.0
[1.0.1]: https://github.com/elarkham/ex_attr/releases/tag/v1.0.1
[1.0.0]: https://github.com/elarkham/ex_attr/releases/tag/v1.0.0
