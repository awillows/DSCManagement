BeforeAll {
    # Remove any existing module and import fresh
    Get-Module DSCManagement -All | Remove-Module -Force -ErrorAction SilentlyContinue
    
    # Import the module being tested
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    Import-Module "$ModuleRoot\DSCManagement.psd1" -Force
    
    # Mock SQL connection for tests that don't require real database
    Mock Open-SqlConnection -ModuleName DSCManagement {
        $mockConnection = New-Object PSObject
        $mockConnection | Add-Member -MemberType ScriptMethod -Name 'CreateCommand' -Value {
            $mockCommand = New-Object PSObject
            $mockCommand | Add-Member -MemberType NoteProperty -Name 'CommandText' -Value ''
            $mockCommand | Add-Member -MemberType NoteProperty -Name 'CommandTimeout' -Value 30
            $mockCommand | Add-Member -MemberType ScriptMethod -Name 'Parameters' -Value {
                @{ AddWithValue = { param($name, $value) } }
            }
            $mockCommand | Add-Member -MemberType ScriptMethod -Name 'ExecuteScalar' -Value { 1 }
            $mockCommand | Add-Member -MemberType ScriptMethod -Name 'Dispose' -Value { }
            return $mockCommand
        }
        $mockConnection | Add-Member -MemberType NoteProperty -Name 'DataSource' -Value 'MockServer'
        $mockConnection | Add-Member -MemberType NoteProperty -Name 'State' -Value 'Open'
        return $mockConnection
    }
    
    Mock Close-SqlConnection -ModuleName DSCManagement { }
    Mock Initialize-Table -ModuleName DSCManagement {
        $mockTable = New-Object System.Data.DataTable
        $mockTable.Columns.Add('Name', [string])
        $mockRow = $mockTable.NewRow()
        $mockRow['Name'] = 'TestEntries'
        $mockTable.Rows.Add($mockRow)
        return $mockTable
    }
}

Describe 'DSCManagement Module' {
    Context 'Module Import' {
        It 'Should import successfully' {
            Get-Module DSCManagement | Should -Not -BeNullOrEmpty
        }
        
        It 'Should export expected functions' {
            $exportedFunctions = (Get-Module DSCManagement).ExportedFunctions.Keys
            $expectedFunctions = @(
                'Get-DscSettings',
                'Get-DscDBTables', 
                'New-DBTableFromResource',
                'Test-DscConnection'
            )
            
            foreach ($function in $expectedFunctions) {
                $exportedFunctions | Should -Contain $function
            }
        }
    }
    
    Context 'Configuration Loading' {
        It 'Should load default configuration' {
            { Get-DscModuleConfig } | Should -Not -Throw
        }
        
        It 'Should return configuration hashtable' {
            $config = Get-DscModuleConfig
            $config | Should -BeOfType [hashtable]
            $config.DefaultServer | Should -Not -BeNullOrEmpty
            $config.DefaultDatabase | Should -Not -BeNullOrEmpty
        }
    }
}