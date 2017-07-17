# PowerShell DSC Settings Management
## A SQL database backed management solution of DSC settings

### Introduction

This project grew from the need to maintain a large number of settings that were to be applied by DSC.

While flat files can be used to store the settings in CSV or XML, the use of a SQL database allows for tighter control over the settings, avoidance of duplication and input errors.

The database also allows for the storage of settings that may not be uniform in their use of properties. For example, a WindowFeature has a number of properties that are optional as below:

~~~~
CoreID               : 1
CorePlatform         : BaseOS
CoreDescription      : Add the Telnet Client to base builds
Name                 : MyTelnetClient
Ensure               : Present
IncludeAllSubFeature :
LogPath              :
Source               : C:\Software\MTC

CoreID               : 2
CorePlatform         : AzureCloud
CoreDescription      : Add IIS
Name                 : IIS
Ensure               : Absent
IncludeAllSubFeature : Yes
LogPath              :
Source               : 
~~~~

This difference in property use can present issues when trying to build dynamic configuration as an attempt to read a property will fail for those with no value. The PowerShell DSC module addresses this by building configuration data based on the fields populated and grouping those usign the same properties for each resource. More details can be found under the `Update-ConfigBlock` description.

### **Function Overview**

**Open-SqlConnection**

Opens a SQL connection (Needs work)

**Close-SqlConnection**

Closes open connection

**Get-DscDBTables**

List the tables currently in the database

**Get-DscSettings**

Outputs all the configuration data stored for a particular resource.

**Initialize-Table**

Reads tables into a `System.Data.DataRow` object.

**New-DBTableForDSCMetadata**

This builds the table for the storage of DSC Resource metadata (Resource Type, Module Version etc.) and a ConfigBlock string which acts as a template for reading in configuration settings.

**New-DBTableFromResource**

Extracts the properties from a DSC resource and creates a new table based on these for storing configuration.

**New-DscMOF**

Outputs a new MOF based on a platform selected. 

**Open-DSCSettings**

Windows Form for editing and viewing table data.

