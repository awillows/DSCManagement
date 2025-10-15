<#
.SYNOPSIS
    Opens a SQL Server connection with proper error handling and security.

.DESCRIPTION
    Creates and opens a SQL Server connection using either integrated security or SQL authentication.
    Supports connection pooling and timeout configuration.

.PARAMETER ComputerName
    The SQL Server instance name. Defaults to '.\SQLEXPRESS'

.PARAMETER Database
    The database name to connect to. Defaults to 'DSC'

.PARAMETER Credential
    Optional PSCredential object for SQL authentication. If not provided, uses integrated security.

.PARAMETER ConnectionTimeout
    Connection timeout in seconds. Defaults to 30 seconds.

.EXAMPLE
    $connection = Open-SqlConnection
    Opens connection to default instance and database with integrated security.

.EXAMPLE
    $cred = Get-Credential
    $connection = Open-SqlConnection -ComputerName 'SqlServer01' -Database 'MyDSC' -Credential $cred
    Opens connection with SQL authentication.
#>
function Open-SqlConnection {
    [CmdletBinding()]
    [OutputType([System.Data.SqlClient.SqlConnection])]
    param (
        [string]$ComputerName = (Get-DscModuleConfig).DefaultServer,
        [string]$Database = (Get-DscModuleConfig).DefaultDatabase,
        [System.Management.Automation.PSCredential]$Credential,
        [int]$ConnectionTimeout = (Get-DscModuleConfig).ConnectionTimeout
    )

    try {
        $connectionStringBuilder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
        $connectionStringBuilder['Server'] = $ComputerName
        $connectionStringBuilder['Database'] = $Database
        $connectionStringBuilder['Connection Timeout'] = $ConnectionTimeout
        $connectionStringBuilder['Pooling'] = (Get-DscModuleConfig).Pooling
        $connectionStringBuilder['Max Pool Size'] = (Get-DscModuleConfig).MaxPoolSize
        $connectionStringBuilder['Min Pool Size'] = (Get-DscModuleConfig).MinPoolSize

        if ($Credential) {
            $connectionStringBuilder['User ID'] = $Credential.UserName
            $connectionStringBuilder['Password'] = $Credential.GetNetworkCredential().Password
        } else {
            $connectionStringBuilder['Integrated Security'] = $true
        }

        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionStringBuilder.ConnectionString)
        
        Write-Verbose "Opening connection to server: $ComputerName, Database: $Database"
        $connection.Open()
        
        Write-Verbose "Connection opened successfully"
        return $connection
    }
    catch {
        Write-Error "Failed to open SQL connection: $($_.Exception.Message)"
        throw
    }
}