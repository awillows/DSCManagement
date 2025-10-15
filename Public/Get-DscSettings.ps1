<#
.SYNOPSIS
    Retrieves DSC settings from the database for a specific resource type.

.DESCRIPTION
    Queries the DSC database to retrieve configuration settings for a specified DSC resource.
    Returns DataRow objects that can be used in PowerShell pipelines for further processing.

.PARAMETER Resource
    The DSC resource name to retrieve settings for (e.g., 'Registry', 'File', 'WindowsFeature').

.PARAMETER Platform
    Optional platform filter to retrieve settings for a specific platform only.

.PARAMETER Connection
    Optional existing SQL connection. If not provided, a new connection will be created.

.EXAMPLE
    Get-DscSettings -Resource 'Registry'
    Retrieves all registry settings from the database.

.EXAMPLE
    Get-DscSettings -Resource 'Log' | Where-Object {$_.Message -eq 'Hello'}
    Retrieves log settings and filters for specific message content.

.EXAMPLE
    Get-DscSettings -Resource 'WindowsFeature' -Platform 'BaseOS'
    Retrieves Windows feature settings for the BaseOS platform only.

.OUTPUTS
    System.Data.DataRow[]
    Returns an array of DataRow objects containing the DSC settings.
#>
function Get-DscSettings {
    [CmdletBinding()]
    [OutputType([System.Data.DataRow[]])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Resource,

        [string]$Platform,

        [System.Data.SqlClient.SqlConnection]$Connection
    )

    $shouldCloseConnection = $false
    
    try {
        # Create connection if not provided
        if (-not $Connection) {
            $Connection = Open-SqlConnection
            $shouldCloseConnection = $true
        }

        # Validate that the resource table exists
        $config = Get-DscModuleConfig
        $requiredTable = $Resource + $config.TableSuffix
        
        $tableCheckQuery = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @TableName"
        
        $command = $Connection.CreateCommand()
        $command.CommandText = $tableCheckQuery
        $null = $command.Parameters.AddWithValue('@TableName', $requiredTable)
        $tableExists = [int]$command.ExecuteScalar()
        $command.Dispose()

        if ($tableExists -eq 0) {
            $availableTables = Get-DscDBTables -Connection $Connection
            $availableResources = $availableTables | ForEach-Object { $_.Name -replace $config.TableSuffix, '' }
            
            Write-Warning "Resource table '$requiredTable' not found."
            Write-Host "`nAvailable DSC Resources:" -ForegroundColor Yellow
            $availableResources | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }
            return
        }

        # Build the query with optional platform filter
        $query = "SELECT * FROM [$requiredTable]"
        $parameters = @{}

        if ($Platform) {
            $query += " WHERE CorePlatform LIKE @Platform"
            $parameters.Platform = "%$Platform%"
        }

        $query += " ORDER BY CoreID"

        $table = Initialize-Table -Connection $Connection -Query $query -Parameters $parameters

        Write-Verbose "Retrieved $($table.Rows.Count) rows for resource '$Resource'"
        
        if ($table.Rows.Count -eq 0) {
            Write-Warning "No settings found for resource '$Resource'"
            if ($Platform) {
                Write-Warning "with platform filter '$Platform'"
            }
        }

        return $table.Rows
    }
    catch {
        Write-Error "Failed to retrieve DSC settings for resource '$Resource': $($_.Exception.Message)"
        throw
    }
    finally {
        if ($shouldCloseConnection -and $Connection) {
            Close-SqlConnection -Connection $Connection
        }
    }
}