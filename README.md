# DSCManagement

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/DSCManagement?style=flat-square)](https://www.powershellgallery.com/packages/DSCManagement)
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/DSCManagement?style=flat-square)](https://www.powershellgallery.com/packages/DSCManagement)
[![License](https://img.shields.io/github/license/awillows/DSCManagement?style=flat-square)](https://github.com/awillows/DSCManagement/blob/master/LICENSE)
[![Build Status](https://img.shields.io/github/actions/workflow/status/awillows/DSCManagement/ci.yml?branch=master&style=flat-square)](https://github.com/awillows/DSCManagement/actions)

A comprehensive PowerShell DSC (Desired State Configuration) settings management solution backed by SQL Server. This module provides centralized configuration management, dynamic MOF generation, and both programmatic and GUI interfaces for managing DSC settings at scale.

## ✨ Features

- **🗄️ SQL Server Backend**: Robust database storage for DSC configurations
- **🔄 Dynamic MOF Generation**: Automatically generate MOF files from database settings
- **🖥️ GUI Management**: Windows Forms interface for easy configuration editing
- **🔒 Security First**: Parameterized queries prevent SQL injection attacks
- **📊 Platform Management**: Support for multiple deployment platforms
- **🎯 Resource Discovery**: Automatic DSC resource table generation
- **⚡ Performance**: Connection pooling and optimized queries
- **📝 Comprehensive Logging**: Detailed logging and error handling

## 🚀 Quick Start

### Prerequisites

- PowerShell 5.1 or later (PowerShell 7+ recommended)
- SQL Server 2012 or later (including Express editions)
- .NET Framework 4.7.2 or later
- Windows PowerShell DSC feature enabled

### Installation

```powershell
# Install from PowerShell Gallery (recommended)
Install-Module -Name DSCManagement -Scope CurrentUser

# Or clone from GitHub
git clone https://github.com/awillows/DSCManagement.git
Import-Module .\DSCManagement\DSCManagement.psd1
```

### Basic Setup

1. **Test Database Connection**:
   ```powershell
   Test-DscConnection
   ```

2. **Create Metadata Table**:
   ```powershell
   New-DBTableForDSCMetadata
   ```

3. **Create Resource Tables**:
   ```powershell
   # Create tables for common DSC resources
   'Registry', 'File', 'WindowsFeature', 'Service' | New-DBTableFromResource
   ```

### Quick Example

```powershell
# Get all registry settings
Get-DscSettings -Resource 'Registry'

# Get settings for a specific platform
Get-DscSettings -Resource 'WindowsFeature' -Platform 'BaseOS'

# Generate MOF file for a platform
New-DscMOF -Platform 'WebServer' -ConfigName 'WebServerConfig'

# Open GUI editor for a resource
Open-DSCSettings -Resource 'Service'
```

## 📖 Architecture Overview

DSCManagement uses a structured approach to manage DSC configurations:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   PowerShell    │    │   SQL Server     │    │   DSC Nodes     │
│     Module      │◄──►│    Database      │    │                 │
│                 │    │                  │    │                 │
│ • Configuration │    │ • Settings       │    │ • Generated     │
│ • MOF Generation│    │ • Metadata       │    │   MOF Files     │
│ • GUI Editor    │    │ • Platform Data  │    │ • Applied       │
│                 │    │                  │    │   Configs       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Database Structure

- **DSCResources Table**: Metadata about DSC resources and configuration templates
- **Resource Tables**: Individual tables for each DSC resource type (e.g., `RegistryEntries`, `FileEntries`)
- **Core Columns**: Every table includes `CoreID`, `CorePlatform`, and `CoreDescription`
- **Dynamic Properties**: Additional columns based on DSC resource properties

### Key Benefits

- **Centralized Management**: Single source of truth for all DSC configurations
- **Platform Flexibility**: Support for multiple deployment scenarios (BaseOS, WebServer, etc.)
- **Property Handling**: Intelligent handling of optional DSC resource properties
- **Version Control**: Database-backed configuration versioning and change tracking

## 🔧 Configuration

### Connection Settings

Create a local configuration file to override defaults:

```powershell
# Config/config.local.psd1
@{
    DefaultServer   = 'MyDscServer\SQLEXPRESS'
    DefaultDatabase = 'MyDSCDatabase'
    LogLevel       = 'Verbose'
    BasePlatform   = 'CompanyStandard'
}
```

### Environment Variables

You can also use environment variables:

```powershell
$env:DSC_SQL_SERVER = 'MyServer\SQLEXPRESS'
$env:DSC_DATABASE = 'MyDSCDB'
```

## 📚 Detailed Usage

### Managing DSC Settings

#### View Available Resources
```powershell
# List all configured DSC resource tables
Get-DscDBTables | Select-Object Name

# Output:
# Name
# ----
# RegistryEntries
# FileEntries
# WindowsFeatureEntries
# ServiceEntries
```

#### Retrieve Settings
```powershell
# Get all registry settings
$registrySettings = Get-DscSettings -Resource 'Registry'

# Filter by platform
$webServerFeatures = Get-DscSettings -Resource 'WindowsFeature' -Platform 'WebServer'

# Use in pipeline
Get-DscSettings -Resource 'Service' | 
    Where-Object { $_.State -eq 'Running' } |
    Select-Object CoreDescription, Name, State
```

#### Generate MOF Files
```powershell
# Generate MOF for specific platform
New-DscMOF -Platform 'WebServer' -ConfigName 'WebServerConfig'

# Debug mode to see generated configuration
New-DscMOF -Platform 'BaseOS' -DebugConfig

# Specify target computer
New-DscMOF -Platform 'DatabaseServer' -ComputerName 'DB01' -ConfigName 'DatabaseConfig'
```

### Advanced Scenarios

#### Multi-Value Columns
```powershell
# Configure a property to split on delimiters
Add-DscMultiValueColumn -Resource 'WindowsFeature' -Property 'IncludeManagementTools' -Delimiter ','
```

#### Custom Resource Tables
```powershell
# Create tables for custom DSC resources
'MyCustomResource', 'CompanySecurityBaseline' | New-DBTableFromResource -Force
```

#### GUI Management
```powershell
# Open Windows Forms editor for any resource
Open-DSCSettings -Resource 'Registry'
Open-DSCSettings -Resource 'Service'
```

## 🔍 Examples

### Example 1: Setting up a Web Server Configuration

```powershell
# 1. Create necessary tables
'WindowsFeature', 'Registry', 'File' | New-DBTableFromResource

# 2. Add Windows Features (this would typically be done via GUI or direct SQL)
# You can use Open-DSCSettings -Resource 'WindowsFeature' to add:
# - IIS-WebServerRole (Ensure: Present)
# - IIS-HttpRedirect (Ensure: Present)
# - IIS-ASPNET45 (Ensure: Present)

# 3. Generate MOF for web servers
New-DscMOF -Platform 'WebServer' -ConfigName 'WebServerConfiguration'

# 4. The generated MOF will include all configured features
```

### Example 2: Managing Registry Settings Across Platforms

```powershell
# Create registry table
New-DBTableFromResource -DscResourceName 'Registry'

# View current registry settings
Get-DscSettings -Resource 'Registry' | Format-Table CorePlatform, Key, ValueName, ValueData

# Generate configuration for specific platform
New-DscMOF -Platform 'Workstation' -ConfigName 'WorkstationRegistry'
```

### Example 3: Bulk Resource Setup

```powershell
# Common DSC resources for enterprise environments
$commonResources = @(
    'Registry',
    'File', 
    'WindowsFeature',
    'Service',
    'User',
    'Group',
    'Environment',
    'WindowsProcess'
)

# Create all tables at once
$commonResources | New-DBTableFromResource -Verbose

# Verify creation
Get-DscDBTables | Select-Object Name
```

## 🛠️ Development

### Building from Source

```bash
git clone https://github.com/awillows/DSCManagement.git
cd DSCManagement

# Run tests
Invoke-Pester -Path .\Tests\

# Run script analyzer
Invoke-ScriptAnalyzer -Path .\Public\, .\Private\ -Settings .\PSScriptAnalyzerSettings.psd1
```

### Contributing

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md).

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

## 📋 Function Reference

### Public Functions

| Function | Description |
|----------|-------------|
| `Get-DscSettings` | Retrieve DSC settings from database |
| `Get-DscDBTables` | List all DSC resource tables |
| `New-DBTableFromResource` | Create database table from DSC resource |
| `New-DBTableForDSCMetadata` | Create metadata table |
| `New-DscMOF` | Generate MOF file from database settings |
| `Open-DSCSettings` | Open GUI editor for resource settings |
| `Test-DscConnection` | Test database connectivity |
| `Add-DscMultiValueColumn` | Configure multi-value property handling |

### Private Functions

| Function | Description |
|----------|-------------|
| `Open-SqlConnection` | Create secure database connection |
| `Close-SqlConnection` | Properly close database connection |
| `Initialize-Table` | Execute parameterized SELECT queries |
| `Invoke-SqlNonQuery` | Execute parameterized non-query commands |
| `Get-DscModuleConfig` | Load module configuration |

## 🔒 Security

- **SQL Injection Protection**: All queries use parameterized commands
- **Connection Security**: Support for both integrated and SQL authentication
- **Credential Management**: Secure handling of database credentials
- **Input Validation**: Comprehensive parameter validation

## 🐛 Troubleshooting

### Common Issues

**Connection Failures**
```powershell
# Test connectivity
Test-DscConnection -Verbose

# Check SQL Server service
Get-Service -Name 'MSSQL$SQLEXPRESS'

# Verify TCP/IP is enabled
# Use SQL Server Configuration Manager
```

**Permission Errors**
```powershell
# Ensure user has necessary database permissions:
# - db_datareader
# - db_datawriter  
# - db_ddladmin (for table creation)
```

**MOF Generation Issues**
```powershell
# Debug generated configuration
New-DscMOF -Platform 'YourPlatform' -DebugConfig

# Check for empty properties
Get-DscSettings -Resource 'YourResource' | 
    Where-Object { [string]::IsNullOrEmpty($_.PropertyName) }
```

### Logging

Enable verbose logging:
```powershell
# Set log level in config
# Config/config.local.psd1
@{
    LogLevel = 'Verbose'
    LogPath = 'C:\Logs\DSCManagement.log'
}
```

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- PowerShell DSC Team for the foundational DSC framework
- SQL Server team for robust database platform
- Community contributors and testers

## 📞 Support

- 🐛 [Report Issues](https://github.com/awillows/DSCManagement/issues)
- 💬 [Discussions](https://github.com/awillows/DSCManagement/discussions)
- 📖 [Wiki](https://github.com/awillows/DSCManagement/wiki)

---

**Made with ❤️ for the PowerShell community**

### **Function Overview**

**Open-SqlConnection**

Opens a SQL connection.

This is called from many functions but it's use is inconsistent. It does contain defaults which will need to be changed to refelct environment specifics.

```powershell
    [CmdletBinding()]
    param (
        [string]$computername = ".\sqlexpress",
        [string]$database = "DSC"
    )
```
This needs more work to improve it's use.

**Close-SqlConnection**

Closes open connection. 

Yep, thats all...

**Get-DscDBTables**

List the tables currently in the database. In it's current form it will just query `sys.tables` for a list of tables in DB. 

~~~
PS C:\> Get-DscDBTables

Name
----
ArchiveEntries
cUserRightsEntries
Entries
EnvironmentEntries
FileEntries
GroupEntries
GroupSetEntries
LogEntries
PackageEntries
ProcessSetEntries
RegistryEntries
ScriptEntries
...
~~~

**Get-DscSettings**

Outputs all the configuration data stored for a particular resource.

Objects returned are of type `System.Data.DataRow` allowing for pipeline operations.

```powershell
PS C:\> Get-DscSettings -Resource Log | Where-Object {$PSItem.Message -eq 'Hello'}

CoreID CorePlatform CoreDescription Message
------ ------------ --------------- -------
     4 BaseOS          Team Message    Hello
```

**Initialize-Table**

This is the main helper function for all calls to read from SQL. It returns a `System.Data.DataTable` object which allows manipulation of the results via the standard PowerShell pipeline.

**New-DBTableForDSCMetadata**

This builds the table for the storage of DSC Resource metadata (Resource Type, Module Version etc.) and a ConfigBlock string which acts as a template for reading in configuration settings.

We reference the values in this table for the creation of the configuration script `New-DscMOF` builds.

We currently store the properties below:

```powershell
PS C:\> $TableEntries | gm -MemberType Properties

   TypeName: System.Data.DataRow

Name                  MemberType Definition
----                  ---------- ----------
ConfigBlock           Property   string ConfigBlock {get;set;}
ResourceModule        Property   string ResourceModule {get;set;}
ResourceModuleVersion Property   string ResourceModuleVersion {get;set;}
ResourceName          Property   string ResourceName {get;set;}
ResourceType          Property   string ResourceType {get;set;}   
```

There is currently an issue with DSC Resources that have no module name. For example the inbox File resource:

```powershell
PS C:\> Get-DscResource -Name File | fl

ResourceType  : MSFT_FileDirectoryConfiguration
Name          : File
FriendlyName  : File
Module        :
ModuleName    :
Version       :
Path          :
ParentPath    : C:\WINDOWS\system32\Configuration\Schema\MSFT_FileDirectoryConfiguration
ImplementedAs : Binary
CompanyName   :
Properties    : {DestinationPath, Attributes, Checksum, Contents...}
```
This appears to be an isolated case but it should be fixed.

**New-DBTableFromResource**

Extracts the properties from a DSC resource and creates a new table based on these for storing configuration.

The column types created will be based on the property types extracts. We currently support:

DSC Property Type | SQL Property Type
------------------|------------------
bool              | bit
string            | varchar(max)
UInt32            | int

If required the `switch` statement can be extended to support new types.

This function does accept pipeline input so an array of DSC Resources names can be passed in to create multiple tables in one batch. 

Following the creation of a new table the DSCResources table is populated with the correct module details and a configuration block for use in `New-DscMOF`.

There is an outstanding piece of work to ensure mandatory resource properties are stored in columns that cannot be NULL.

**New-DscMOF**

Outputs a new MOF based on a platform selected. 

By referencing the values stored in the DSCResources table a configuration script is built dynamically and then executed. There is a `-DebugConfig` switch available if you would like to view the script as this can be useful for troubleshooting.

The function makes a call to `Update-ConfigBlock` to ensure we don't hit issues with empty properties being read by the configuration script.

If no records are found for a speicfied platform we will dump the in-memory script for review. 

NOTE:

> The `-Platform` parameter value is wildcarded before being sent to SQL. This should be taken into account as creating similar platform names could lead to unexpected results. For example, if using `BaseOS` and `BaseOSv2`, searching for `BaseOS` will return both. This can be avoided by Full-Text indexing the tables and amending the query to perform a CONTAINS().

**Open-DSCSettings**

This prosents a Windows Form for editing and viewing table data. This is still very much work in progress but it provides basic functionality to add/delete and query records.

**Update-ConfigBlock**

This will take a base configuration block and remove the redundant entries based on the columns
used in the DataRow record. If we do not remove these errors will be thrown as any empty string will be used for the value which isn't supported by many properties.

For Example, for the record below:

~~~
   Name                 : All
   Ensure               : 
   IncludeAllSubFeature : True
   LogPath              : C:\Logs
   Source               : 
~~~

We will change this ConfigBlock:

```powershell
{Name = $row.Name;Ensure = $row.Ensure;IncludeAllSubFeature = $row.IncludeAllSubFeature;LogPath = $row.LogPath;Source = $row.Source;}}
```

To this:

```powershell
{Name = $row.Name;IncludeAllSubFeature = $row.IncludeAllSubFeature;LogPath = $row.LogPath;}}
```

This ensures the unused columns of `Ensure`and `Source` are not referenced during configuration script compile.

In order to identify those properties to be removed we create a hash table of all properties and an associated bit value.

~~~
Name                           Value
----                           -----
1                              CoreID
2                              CorePlatform
4                              CoreDescription
8                              Name
16                             Ensure
32                             IncludeAllSubFeature
64                             LogPath
128                            Source   
~~~

Once we've created this hashtable we can then the loop through the records and build a bitmask that will map empty properties. These records will then be added to a new table.

```powershell
if(!$row.IsNull($i))
{
    # Need to build bitmask of populated columns
    $bitMaskValue = $bitMaskValue + [Math]::Pow(2, $i)
}
```

The result will be multiple arrays of Datarows that all share a common set of populated properties.

### Sample DSC Configuration Script created in memory

```powershell
Configuration MySettings {
Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
Import-DscResource -ModuleName cUserRights -ModuleVersion 1.0.0.1
Import-DscResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 3.12.0.1
node localhost {
# No records found for RegistryEntries with Platform of BaseOS
foreach($row in $newDSCLogEntries15) { Log $row.CoreDescription {Message = $row.Message;}}
# No records found for cUserRightsEntries with Platform of BaseOS
foreach($row in $newDSCWindowsFeatureEntries15) { WindowsFeature $row.CoreDescription {Name = $row.Name;}}
# No records found for xRegistryEntries with Platform of BaseOS
}}
MySettings
```