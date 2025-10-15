<#
.SYNOPSIS
    Tests the connection to the DSC database.

.DESCRIPTION
    Verifies that the module can successfully connect to the configured SQL Server
    database and validates that required tables exist.

.PARAMETER ComputerName
    The SQL Server instance name. If not specified, uses the default from configuration.

.PARAMETER Database
    The database name. If not specified, uses the default from configuration.

.PARAMETER Credential
    Optional PSCredential for SQL authentication. If not provided, uses integrated security.

.EXAMPLE
    Test-DscConnection
    Tests connection using default settings.

.EXAMPLE
    Test-DscConnection -ComputerName 'SqlServer01' -Database 'MyDSC'
    Tests connection to a specific server and database.

.EXAMPLE
    $cred = Get-Credential
    Test-DscConnection -Credential $cred
    Tests connection using SQL authentication.

.OUTPUTS
    System.Boolean
    Returns $true if connection is successful, $false otherwise.
#>
function Test-DscConnection {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [string]$ComputerName,
        [string]$Database,
        [System.Management.Automation.PSCredential]$Credential
    )

    try {
        $connectionParams = @{}
        if ($ComputerName) { $connectionParams.ComputerName = $ComputerName }
        if ($Database) { $connectionParams.Database = $Database }
        if ($Credential) { $connectionParams.Credential = $Credential }

        $connection = Open-SqlConnection @connectionParams
        
        # Test basic connectivity
        $testQuery = "SELECT 1 as TestValue"
        $result = Initialize-Table -Connection $connection -Query $testQuery
        
        if ($result.Rows.Count -eq 1 -and $result.Rows[0].TestValue -eq 1) {
            Write-Host "✓ Database connection successful" -ForegroundColor Green
            
            # Check for DSCResources metadata table
            $metadataQuery = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DSCResources'"
            $command = $connection.CreateCommand()
            $command.CommandText = $metadataQuery
            $metadataExists = [int]$command.ExecuteScalar()
            $command.Dispose()
            
            if ($metadataExists -gt 0) {
                Write-Host "✓ DSCResources metadata table found" -ForegroundColor Green
            } else {
                Write-Warning "DSCResources metadata table not found. Run New-DBTableForDSCMetadata to create it."
            }
            
            # List available DSC tables
            $tables = Get-DscDBTables -Connection $connection
            if ($tables.Count -gt 0) {
                Write-Host "✓ Found $($tables.Count) DSC resource tables:" -ForegroundColor Green
                $tables | ForEach-Object { 
                    $resourceName = $_.Name -replace (Get-DscModuleConfig).TableSuffix, ''
                    Write-Host "  - $resourceName" -ForegroundColor Cyan
                }
            } else {
                Write-Warning "No DSC resource tables found. Use New-DBTableFromResource to create them."
            }
            
            return $true
        } else {
            Write-Error "Database connection test failed"
            return $false
        }
    }
    catch {
        Write-Error "Connection test failed: $($_.Exception.Message)"
        return $false
    }
    finally {
        if ($connection) {
            Close-SqlConnection -Connection $connection
        }
    }
}