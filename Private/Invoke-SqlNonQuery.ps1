<#
.SYNOPSIS
    Executes a non-query SQL command with parameters.

.DESCRIPTION
    Helper function for executing INSERT, UPDATE, DELETE commands with proper
    parameter handling to prevent SQL injection.

.PARAMETER Connection
    The SQL connection object to use.

.PARAMETER Query
    The SQL command to execute.

.PARAMETER Parameters
    Hashtable of parameters for the SQL command.

.EXAMPLE
    $params = @{ ResourceName = 'File'; ConfigBlock = $configBlock }
    Invoke-SqlNonQuery -Connection $conn -Query "UPDATE DSCResources SET ConfigBlock = @ConfigBlock WHERE ResourceName = @ResourceName" -Parameters $params
#>
function Invoke-SqlNonQuery {
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]$Connection,
        
        [Parameter(Mandatory)]
        [string]$Query,
        
        [hashtable]$Parameters = @{}
    )

    Write-Verbose "Executing non-query: $Query"
    
    try {
        $command = $Connection.CreateCommand()
        $command.CommandText = $Query
        $command.CommandTimeout = (Get-DscModuleConfig).CommandTimeout

        # Add parameters to prevent SQL injection
        foreach ($param in $Parameters.GetEnumerator()) {
            $null = $command.Parameters.AddWithValue("@$($param.Key)", $param.Value)
            Write-Verbose "Added parameter: @$($param.Key) = $($param.Value)"
        }

        $rowsAffected = $command.ExecuteNonQuery()
        Write-Verbose "Command affected $rowsAffected rows"
        
        return $rowsAffected
    }
    catch {
        Write-Error "Failed to execute non-query command: $($_.Exception.Message)"
        throw
    }
    finally {
        if ($command) {
            $command.Dispose()
        }
    }
}