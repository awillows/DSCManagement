# Contributing to DSCManagement

We love your input! We want to make contributing to DSCManagement as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## Development Process

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

### Pull Requests

Pull requests are the best way to propose changes to the codebase. We actively welcome your pull requests:

1. **Fork the repo** and create your branch from `master`
2. **Add tests** if you've added code that should be tested
3. **Update documentation** if you've changed APIs
4. **Run the test suite** and ensure tests pass
5. **Run PSScriptAnalyzer** and fix any issues
6. **Issue the pull request**

### Development Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/awillows/DSCManagement.git
   cd DSCManagement
   ```

2. **Install development dependencies**:
   ```powershell
   # Install Pester for testing
   Install-Module -Name Pester -Force -SkipPublisherCheck
   
   # Install PSScriptAnalyzer for linting
   Install-Module -Name PSScriptAnalyzer -Force
   ```

3. **Set up test database** (if testing database functions):
   ```powershell
   # Create test database or use SQL Express
   # Update Config/config.local.psd1 with test connection details
   ```

### Code Style

We follow PowerShell best practices and use PSScriptAnalyzer to enforce coding standards:

- **Use approved verbs** for function names (`Get-`, `Set-`, `New-`, etc.)
- **Use PascalCase** for function names and parameters
- **Include comment-based help** for all public functions
- **Use proper error handling** with try/catch blocks
- **Validate parameters** using `[ValidateNotNullOrEmpty()]` and similar attributes
- **Use verbose output** for debugging information

### Running Tests

```powershell
# Run all tests
Invoke-Pester -Path .\Tests\

# Run specific test file
Invoke-Pester -Path .\Tests\Public\Get-DscSettings.Tests.ps1

# Run with coverage
Invoke-Pester -Path .\Tests\ -CodeCoverage .\Public\*.ps1
```

### Code Analysis

```powershell
# Run PSScriptAnalyzer on all code
Invoke-ScriptAnalyzer -Path .\Public\, .\Private\ -Settings .\PSScriptAnalyzerSettings.psd1

# Fix formatting issues automatically
Invoke-Formatter -ScriptDefinition (Get-Content .\Public\Get-DscSettings.ps1 -Raw)
```

## Types of Contributions

### 🐛 Bug Reports

Great bug reports tend to have:

- **Quick summary** and/or background
- **Steps to reproduce** - be specific and give sample code if possible
- **What you expected** would happen
- **What actually happens**
- **Additional context** - screenshots, error messages, environment details

Use our bug report template when creating issues.

### 💡 Feature Requests

We welcome feature requests! Please:

- **Use the feature request template**
- **Explain the motivation** - what problem does this solve?
- **Describe the solution** - what should the API look like?
- **Consider alternatives** - what other approaches could work?
- **Check existing issues** - has this been requested before?

### 📝 Documentation

Documentation improvements are always welcome:

- **Fix typos** and grammar issues
- **Add examples** for existing functions
- **Improve clarity** of explanations
- **Add missing documentation** for parameters or functions
- **Update outdated information**

### 🔧 Code Contributions

When contributing code:

#### Function Guidelines

**Public Functions**:
- Must include complete comment-based help
- Must include parameter validation
- Must include error handling
- Must include at least one example
- Should support common parameters (`-Verbose`, `-WhatIf` where appropriate)

**Private Functions**:
- Should include basic comment-based help
- Must include error handling for critical operations
- Should use `Write-Verbose` for debugging information

#### Example Function Template

```powershell
<#
.SYNOPSIS
    Brief description of what the function does.

.DESCRIPTION
    Detailed description of the function's purpose and behavior.

.PARAMETER ParameterName
    Description of what this parameter does.

.EXAMPLE
    Example-Function -ParameterName 'Value'
    Description of what this example does.

.OUTPUTS
    Type of objects returned by this function.

.NOTES
    Additional information about the function.
#>
function Example-Function {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ParameterName
    )

    try {
        Write-Verbose "Starting Example-Function with parameter: $ParameterName"
        
        # Function logic here
        
        Write-Verbose "Example-Function completed successfully"
        return $result
    }
    catch {
        Write-Error "Example-Function failed: $($_.Exception.Message)"
        throw
    }
}
```

#### Database Function Guidelines

- **Always use parameterized queries** to prevent SQL injection
- **Include connection management** - open and close connections properly
- **Handle timeouts** gracefully
- **Validate SQL objects exist** before operating on them
- **Use transactions** for multi-statement operations

#### Security Guidelines

- **Never concatenate user input** directly into SQL strings
- **Validate all input parameters** before use
- **Use secure connection strings** (no plain-text passwords)
- **Handle credentials securely** using PSCredential objects
- **Log security-relevant events** appropriately

### Testing Guidelines

#### Unit Tests

Write unit tests for:
- **All public functions**
- **Complex private functions**
- **Error handling scenarios**
- **Edge cases and boundary conditions**

#### Integration Tests

Write integration tests for:
- **Database operations**
- **MOF generation**
- **Multi-function workflows**

#### Test Structure

```powershell
Describe 'Get-DscSettings' {
    BeforeAll {
        # Setup test environment
    }
    
    Context 'When resource exists' {
        It 'Should return settings for valid resource' {
            # Test implementation
        }
        
        It 'Should filter by platform when specified' {
            # Test implementation
        }
    }
    
    Context 'When resource does not exist' {
        It 'Should show available resources' {
            # Test implementation
        }
    }
    
    Context 'Error handling' {
        It 'Should throw meaningful error on connection failure' {
            # Test implementation
        }
    }
}
```

## Submitting Changes

### Commit Messages

Use clear and meaningful commit messages:

```
feat: add support for custom DSC resources
fix: resolve SQL injection vulnerability in Get-DscSettings
docs: update README with new examples
test: add unit tests for New-DBTableFromResource
refactor: improve error handling in database functions
```

### Pull Request Process

1. **Create a feature branch** from `master`
2. **Make your changes** following the guidelines above
3. **Add or update tests** for your changes
4. **Update documentation** if needed
5. **Run the full test suite** and ensure all tests pass
6. **Run PSScriptAnalyzer** and fix any issues
7. **Submit the pull request** with a clear description

### Pull Request Template

When submitting a PR, please include:

- **Summary of changes**
- **Type of change** (bug fix, feature, documentation, etc.)
- **Testing performed**
- **Screenshots** (if applicable)
- **Breaking changes** (if any)

## Community Guidelines

### Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md).

### Getting Help

- **GitHub Discussions**: For general questions and community support
- **Issues**: For bug reports and feature requests
- **Wiki**: For detailed documentation and guides

### Recognition

Contributors will be recognized in:
- **CHANGELOG.md** for significant contributions
- **README.md** acknowledgments section
- **Release notes** for major features

## License

By contributing to DSCManagement, you agree that your contributions will be licensed under the MIT License.

## Questions?

Feel free to contact the maintainers if you have any questions about contributing!