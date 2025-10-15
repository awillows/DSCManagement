<#
.SYNOPSIS
    Closes a SQL Server connection safely.

.DESCRIPTION
    Properly closes and disposes of a SQL Server connection object with error handling.

.PARAMETER Connection
    The SQL connection object to close.

.EXAMPLE
    Close-SqlConnection -Connection $connection
#>
function Close-SqlConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]$Connection
    )

    if ($Connection -and $Connection.State -ne [System.Data.ConnectionState]::Closed) {
        try {
            Write-Verbose "Closing connection to: $($Connection.DataSource)"
            $Connection.Close()
            $Connection.Dispose()
        }
        catch {
            Write-Warning "Error closing SQL connection: $($_.Exception.Message)"
        }
    }
}