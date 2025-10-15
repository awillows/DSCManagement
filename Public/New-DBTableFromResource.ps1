<#
.SYNOPSIS
    Creates a new database table for storing DSC resource configuration data.

.DESCRIPTION
    Extracts properties from a DSC resource and creates a corresponding database table
    with appropriate column types. Also updates the DSCResources metadata table with
    module information and configuration templates.

.PARAMETER DscResourceName
    The name of the DSC resource to create a table for. Accepts pipeline input.

.PARAMETER Connection
    Optional existing SQL connection. If not provided, a new connection will be created.

.PARAMETER Force
    If specified, will drop and recreate the table if it already exists.

.EXAMPLE
    New-DBTableFromResource -DscResourceName 'Registry'
    Creates a table for storing Registry DSC resource settings.

.EXAMPLE
    'File', 'Registry', 'WindowsFeature' | New-DBTableFromResource
    Creates tables for multiple DSC resources via pipeline.

.EXAMPLE
    New-DBTableFromResource -DscResourceName 'Service' -Force
    Recreates the Service table, dropping the existing one first.

.OUTPUTS
    None. Writes progress information to the console.
#>
function New-DBTableFromResource {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$DscResourceName,

        [System.Data.SqlClient.SqlConnection]$Connection,

        [switch]$Force
    )

    begin {
        $shouldCloseConnection = $false
        
        if (-not $Connection) {
            $Connection = Open-SqlConnection
            $shouldCloseConnection = $true
        }

        $config = Get-DscModuleConfig
        Write-Verbose "Starting table creation process..."
    }

    process {
        foreach ($resourceName in $DscResourceName) {
            try {
                Write-Verbose "Processing DSC resource: $resourceName"

                # Get DSC resource information
                $dscResource = Get-DscResource -Name $resourceName -ErrorAction Stop
                
                # Handle multiple versions
                if ($dscResource.Count -gt 1) {
                    Write-Warning "Multiple versions found for resource '$resourceName':"
                    $dscResource | ForEach-Object { Write-Warning "  Version: $($_.Version)" }
                    $dscResource = $dscResource | Sort-Object Version -Descending | Select-Object -First 1
                    Write-Warning "Using version: $($dscResource.Version)"
                }

                $tableName = $resourceName + $config.TableSuffix

                # Check if table exists
                $tableExistsQuery = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @TableName"
                $command = $Connection.CreateCommand()
                $command.CommandText = $tableExistsQuery
                $null = $command.Parameters.AddWithValue('@TableName', $tableName)
                $tableExists = [int]$command.ExecuteScalar()
                $command.Dispose()

                if ($tableExists -gt 0) {
                    if ($Force) {
                        if ($PSCmdlet.ShouldProcess($tableName, "Drop and recreate table")) {
                            Write-Warning "Dropping existing table: $tableName"
                            $dropQuery = "DROP TABLE [$tableName]"
                            Invoke-SqlNonQuery -Connection $Connection -Query $dropQuery
                        }
                    } else {
                        Write-Warning "Table '$tableName' already exists. Use -Force to recreate."
                        continue
                    }
                }

                if ($PSCmdlet.ShouldProcess($tableName, "Create DSC resource table")) {
                    # Create base table with core columns
                    $createTableQuery = "CREATE TABLE [$tableName] ("
                    
                    foreach ($coreColumn in $config.CoreColumns) {
                        $createTableQuery += "[$($coreColumn.Name)] $($coreColumn.Type)"
                        
                        if ($coreColumn.Identity) {
                            $createTableQuery += " IDENTITY(1,1)"
                        }
                        
                        if ($coreColumn.Required) {
                            $createTableQuery += " NOT NULL"
                        }
                        
                        $createTableQuery += ","
                    }
                    
                    # Add primary key
                    $pkColumn = ($config.CoreColumns | Where-Object { $_.PrimaryKey }).Name
                    $createTableQuery += "PRIMARY KEY CLUSTERED ([$pkColumn] ASC)"
                    $createTableQuery += ")"

                    Invoke-SqlNonQuery -Connection $Connection -Query $createTableQuery
                    Write-Host "✓ Created table: $tableName" -ForegroundColor Green

                    # Add columns for DSC resource properties
                    $configBlock = "foreach(`$row in `$$tableName) { $($dscResource.Name) `$row.CoreDescription {"
                    
                    foreach ($property in $dscResource.Properties) {
                        # Skip DependsOn as it's handled differently
                        if ($property.Name -eq 'DependsOn') { continue }
                        
                        # Handle SQL keywords
                        $columnName = $property.Name
                        if ($property.Name -in $config.SqlKeywords) {
                            $columnName = $property.Name + 'Name'
                        }

                        # Determine SQL data type based on PowerShell type
                        $sqlType = switch -Wildcard ($property.PropertyType) {
                            'string*' { 'varchar(max)' }
                            'bool*' { 'bit' }
                            'UInt32*' { 'int' }
                            'UInt64*' { 'bigint' }
                            'DateTime*' { 'datetime2' }
                            default { 'varchar(max)' }
                        }

                        # Add column to table
                        $addColumnQuery = "ALTER TABLE [$tableName] ADD [$columnName] $sqlType"
                        Invoke-SqlNonQuery -Connection $Connection -Query $addColumnQuery
                        
                        # Add to configuration block
                        $propertyName = if ($property.Name -in $config.SqlKeywords) { $property.Name } else { $columnName }
                        $configBlock += "$propertyName = `$row.$columnName;"
                    }
                    
                    $configBlock += "}}"

                    # Update DSCResources metadata table
                    $moduleName = if ($dscResource.ModuleName) { $dscResource.ModuleName } else { 'PSDesiredStateConfiguration' }
                    $moduleVersion = if ($dscResource.Version) { $dscResource.Version.ToString() } else { '1.1' }

                    $metadataQuery = @"
                        INSERT INTO DSCResources (ResourceName, ResourceModule, ResourceModuleVersion, ResourceType, ConfigBlock)
                        VALUES (@ResourceName, @ResourceModule, @ResourceModuleVersion, @ResourceType, @ConfigBlock)
"@
                    
                    $metadataParams = @{
                        ResourceName = $dscResource.Name
                        ResourceModule = $moduleName
                        ResourceModuleVersion = $moduleVersion
                        ResourceType = $dscResource.ResourceType
                        ConfigBlock = $configBlock
                    }

                    Invoke-SqlNonQuery -Connection $Connection -Query $metadataQuery -Parameters $metadataParams
                    Write-Host "✓ Updated DSCResources metadata for: $($dscResource.Name)" -ForegroundColor Green
                }
            }
            catch {
                Write-Error "Failed to create table for resource '$resourceName': $($_.Exception.Message)"
            }
        }
    }

    end {
        if ($shouldCloseConnection -and $Connection) {
            Close-SqlConnection -Connection $Connection
        }
        Write-Verbose "Table creation process completed"
    }
}