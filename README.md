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

