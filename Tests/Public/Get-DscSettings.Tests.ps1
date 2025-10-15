BeforeAll {
    # Import the module being tested
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module "$ModuleRoot\DSCManagement.psd1" -Force
    
    # Create mock objects for testing
    $mockConnection = New-Object PSObject
    $mockConnection | Add-Member -MemberType ScriptMethod -Name 'CreateCommand' -Value {
        $mockCommand = New-Object PSObject
        $mockCommand | Add-Member -MemberType NoteProperty -Name 'CommandText' -Value ''
        $mockCommand | Add-Member -MemberType ScriptMethod -Name 'Parameters' -Value {
            @{ AddWithValue = { param($name, $value) } }
        }
        $mockCommand | Add-Member -MemberType ScriptMethod -Name 'ExecuteScalar' -Value { 1 }
        $mockCommand | Add-Member -MemberType ScriptMethod -Name 'Dispose' -Value { }
        return $mockCommand
    }
}

Describe 'Get-DscSettings' {
    BeforeEach {
        # Mock the private functions
        Mock Open-SqlConnection -ModuleName DSCManagement { return $mockConnection }
        Mock Close-SqlConnection -ModuleName DSCManagement { }
        Mock Initialize-Table -ModuleName DSCManagement {
            $mockTable = New-Object System.Data.DataTable
            $mockTable.Columns.Add('CoreID', [int])
            $mockTable.Columns.Add('CorePlatform', [string])
            $mockTable.Columns.Add('CoreDescription', [string])
            $mockTable.Columns.Add('Name', [string])
            
            $row1 = $mockTable.NewRow()
            $row1['CoreID'] = 1
            $row1['CorePlatform'] = 'BaseOS'
            $row1['CoreDescription'] = 'Test Registry Setting'
            $row1['Name'] = 'TestKey'
            $mockTable.Rows.Add($row1)
            
            return $mockTable
        }
        Mock Get-DscDBTables -ModuleName DSCManagement {
            $mockResult = @(
                @{ Name = 'RegistryEntries' },
                @{ Name = 'FileEntries' }
            )
            return $mockResult
        }
    }
    
    Context 'Parameter Validation' {
        It 'Should throw when Resource parameter is empty' {
            { Get-DscSettings -Resource '' } | Should -Throw
        }
        
        It 'Should throw when Resource parameter is null' {
            { Get-DscSettings -Resource $null } | Should -Throw
        }
        
        It 'Should accept valid Resource parameter' {
            { Get-DscSettings -Resource 'Registry' } | Should -Not -Throw
        }
    }
    
    Context 'When resource table exists' {
        BeforeEach {
            # Mock table existence check to return true
            Mock -CommandName 'Invoke-Command' -ModuleName DSCManagement -MockWith { 1 }
        }
        
        It 'Should return settings for valid resource' {
            $result = Get-DscSettings -Resource 'Registry'
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].Name | Should -Be 'TestKey'
        }
        
        It 'Should accept platform filter' {
            { Get-DscSettings -Resource 'Registry' -Platform 'BaseOS' } | Should -Not -Throw
        }
        
        It 'Should accept existing connection' {
            { Get-DscSettings -Resource 'Registry' -Connection $mockConnection } | Should -Not -Throw
        }
    }
    
    Context 'When resource table does not exist' {
        BeforeEach {
            # Mock table existence check to return false
            Mock -CommandName 'Initialize-Table' -ModuleName DSCManagement -ParameterFilter {
                $Query -like '*INFORMATION_SCHEMA.TABLES*'
            } -MockWith {
                $mockTable = New-Object System.Data.DataTable
                $mockTable.Columns.Add('COUNT', [int])
                $row = $mockTable.NewRow()
                $row['COUNT'] = 0
                $mockTable.Rows.Add($row)
                return $mockTable
            }
        }
        
        It 'Should show available resources when table does not exist' {
            $result = Get-DscSettings -Resource 'NonExistentResource' -WarningAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Error Handling' {
        It 'Should handle connection errors gracefully' {
            Mock Open-SqlConnection -ModuleName DSCManagement { throw 'Connection failed' }
            
            { Get-DscSettings -Resource 'Registry' } | Should -Throw '*Connection failed*'
        }
        
        It 'Should handle query errors gracefully' {
            Mock Initialize-Table -ModuleName DSCManagement { throw 'Query failed' }
            
            { Get-DscSettings -Resource 'Registry' } | Should -Throw '*Query failed*'
        }
    }
    
    Context 'Verbose Output' {
        It 'Should write verbose messages when -Verbose is used' {
            Mock Write-Verbose -ModuleName DSCManagement { }
            
            Get-DscSettings -Resource 'Registry' -Verbose
            
            Assert-MockCalled Write-Verbose -ModuleName DSCManagement -AtLeast 1
        }
    }
}