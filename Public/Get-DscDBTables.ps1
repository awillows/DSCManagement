<#
.SYNOPSIS
    Retrieves a list of all DSC resource tables in the database.

.DESCRIPTION
    Queries the database to return all tables that follow the DSC naming convention
    (tables ending with 'Entries' suffix). This helps identify what DSC resources
    have been configured in the database.

.PARAMETER Connection
    Optional existing SQL connection. If not provided, a new connection will be created.

.EXAMPLE
    Get-DscDBTables
    Returns all DSC resource tables in the database.

.EXAMPLE
    $tables = Get-DscDBTables
    $tables | Select-Object Name
    Gets table names and displays them.

.OUTPUTS
    System.Data.DataRow[]
    Returns DataRow objects containing table information.
#>
function Get-DscDBTables {
    [CmdletBinding()]
    [OutputType([System.Data.DataRow[]])]
    param (
        [System.Data.SqlClient.SqlConnection]$Connection
    )

    $shouldCloseConnection = $false
    
    try {
        # Create connection if not provided
        if (-not $Connection) {
            $Connection = Open-SqlConnection
            $shouldCloseConnection = $true
        }

        $config = Get-DscModuleConfig
        $query = "SELECT TABLE_NAME as Name FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE @Pattern AND TABLE_TYPE = 'BASE TABLE'"
        $parameters = @{ Pattern = "%$($config.TableSuffix)" }

        $table = Initialize-Table -Connection $Connection -Query $query -Parameters $parameters
        
        Write-Verbose "Found $($table.Rows.Count) DSC resource tables"
        
        return $table.Rows
    }
    catch {
        Write-Error "Failed to retrieve DSC database tables: $($_.Exception.Message)"
        throw
    }
    finally {
        if ($shouldCloseConnection -and $Connection) {
            Close-SqlConnection -Connection $Connection
        }
    }
}