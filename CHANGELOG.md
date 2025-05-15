# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New utility method `generate_files_from_content` for better integration with external gems
- New documentation for Chef CLI integration
- Debug flags and environment variables to help troubleshoot integration issues
- Example integration code for Chef CLI

### Fixed
- Issue with generate command showing raw JSON when integrated with Chef CLI
- Improved JSON parsing to handle a wider variety of AI response formats
- Better error handling in generate command

## [0.1.0] - 2025-05-08

### Added
- Initial release of the gem
- Basic project structure