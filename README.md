# PowerShell DSC Settings Management
## A SQL database backed management solution of DSC settings

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

This difference in property use can present issues when trying to build dynamic configuration as an attempt to read the value will fail for those with no value. The PowerShell DSC module addresses this by building configuration data based on the fields populated and grouping those usign the same properties for each resource.