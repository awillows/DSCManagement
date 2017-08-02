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

List the tables currently in the database. 

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

By refernencing the values stored in the DSCResources a configuration script is built dynamically and then executed. There is a DebugConfig switch available if you would like to view the script as this can be useful for troubleshooting.

The function makes a call to `Update-ConfigBlock` to ensure we don't hit issues with empty properties being read by the configuration script.

**Open-DSCSettings**

Windows Form for editing and viewing table data.

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

`{Name = $row.Name;Ensure = $row.Ensure;IncludeAllSubFeature = $row.IncludeAllSubFeature;LogPath = $row.LogPath;Source = $row.Source;}}`

To this:

`{Name = $row.Name;IncludeAllSubFeature = $row.IncludeAllSubFeature;LogPath = $row.LogPath;}}`

This ensures the unused columns of 'Ensure' and 'Source' are not referenced during configuration script compile.

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

~~~
if(!$row.IsNull($i))
{
    # Need to build bitmask of populated columns
    $bitMaskValue = $bitMaskValue + [Math]::Pow(2, $i)
}
~~~

The result will be multiple arrays of Datarows that all share a common set of populated properties.