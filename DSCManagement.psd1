@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'DSCManagement.psm1'

    # Version number of this module.
    ModuleVersion = '2.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

    # Author of this module
    Author = 'awillows'

    # Company or vendor of this module
    CompanyName = 'Unknown'

    # Copyright statement for this module
    Copyright = '(c) 2025 awillows. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'A comprehensive PowerShell DSC (Desired State Configuration) settings management solution backed by SQL Server. Provides dynamic MOF generation, GUI-based configuration editing, and centralized DSC resource management.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    DotNetFrameworkVersion = '4.7.2'

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # ClrVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Get-DscSettings',
        'New-DscMOF',
        'Get-DscDBTables',
        'New-DBTableFromResource',
        'Open-DSCSettings',
        'New-DBTableForDSCMetadata',
        'Add-DscMultiValueColumn',
        'Get-DscConfiguration',
        'Set-DscConfiguration',
        'Test-DscConnection'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('DSC', 'DesiredStateConfiguration', 'Configuration', 'Management', 'SQL', 'Database', 'MOF', 'Windows')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/awillows/DSCManagement/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/awillows/DSCManagement'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = @'
## Version 2.0.0

### Major Changes
- Complete module restructure with Public/Private function separation
- Added comprehensive security fixes for SQL injection vulnerabilities
- Implemented parameterized database queries throughout
- Added configuration file support for connection strings
- Enhanced error handling and parameter validation

### New Features
- PowerShell Script Analyzer integration
- Comprehensive Pester tests
- GitHub Actions CI/CD workflows
- Comment-based help for all functions
- Modern PowerShell practices implementation

### Security Improvements
- Fixed SQL injection vulnerabilities
- Implemented secure credential management
- Added input validation and sanitization

### Documentation
- Comprehensive README with examples
- Contributing guidelines
- Code of conduct
- Architecture documentation

For full changelog, see CHANGELOG.md
'@

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()
        } # End of PSData hashtable
    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}