# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive project restructure with Public/Private function separation
- Module manifest (DSCManagement.psd1) with proper metadata
- PowerShell Script Analyzer configuration
- Pester tests for all public functions
- GitHub Actions CI/CD workflows
- Comment-based help for all functions
- Configuration file support for connection strings
- SQL injection protection with parameterized queries
- Comprehensive documentation (README, CONTRIBUTING, etc.)
- Code of Conduct

### Changed
- Improved error handling throughout the module
- Enhanced parameter validation
- Modern PowerShell practices implementation
- Better separation of concerns

### Security
- Fixed SQL injection vulnerabilities
- Implemented parameterized database queries
- Added credential management best practices

## [1.0.0] - 2025-10-15

### Added
- Initial release of DSCManagement module
- SQL Server backed DSC configuration management
- Core functions for managing DSC settings
- Windows Forms GUI for data editing
- Dynamic MOF generation from database settings