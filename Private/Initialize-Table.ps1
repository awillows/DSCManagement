<#
.SYNOPSIS
    Executes a SQL query and returns results as a DataTable.

.DESCRIPTION
    Helper function that executes a SELECT query against SQL Server and returns the results
    as a DataTable object for further processing. Uses parameterized queries to prevent SQL injection.

.PARAMETER Connection
    The SQL connection object to use for the query.

.PARAMETER Query
    The SQL SELECT query to execute.

.PARAMETER Parameters
    Optional hashtable of parameters for the SQL query.

.EXAMPLE
    $params = @{ Platform = 'BaseOS' }
    $table = Initialize-Table -Connection $connection -Query "SELECT * FROM Entries WHERE CorePlatform = @Platform" -Parameters $params
#>
function Initialize-Table {
    [CmdletBinding()]
    [OutputType([System.Data.DataTable])]
    param (
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]$Connection,
        
        [Parameter(Mandatory)]
        [string]$Query,
        
        [hashtable]$Parameters = @{}
    )

    Write-Verbose "Executing query: $Query"
    
    try {
        $command = $Connection.CreateCommand()
        $command.CommandText = $Query
        $command.CommandTimeout = (Get-DscModuleConfig).CommandTimeout

        # Add parameters to prevent SQL injection
        foreach ($param in $Parameters.GetEnumerator()) {
            $parameter = $command.Parameters.AddWithValue("@$($param.Key)", $param.Value)
            Write-Verbose "Added parameter: @$($param.Key) = $($param.Value)"
        }

        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
        $table = New-Object System.Data.DataTable
        $rowCount = $adapter.Fill($table)
        
        Write-Verbose "Query returned $rowCount rows"
        return $table
    }
    catch {
        Write-Error "Failed to execute query: $($_.Exception.Message)"
        throw
    }
    finally {
        if ($command) {
            $command.Dispose()
        }
        if ($adapter) {
            $adapter.Dispose()
        }
    }
}