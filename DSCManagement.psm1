# Function to pull all tables containing DSC settings. Should be called from anywhere that a partial set may need to be build.

function Get-DSCDBtables
{
    $conn = Open-SqlConnection
    $selectcommand = $selectcommand = "SELECT TABLE_NAME AS Name FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE '%Entries'"
    $dbtables = Initialize-Table -connection $conn -query $selectcommand

    return $dbtables
}

# New-DBTableFromResource can be used to quickly create tables based on the properties of the DSC Resource.
# Any further alterations can be made directly through SSMS. 

function New-DBTableFromResource
{
   [CmdletBinding()]
    param (
        [string]$DscResName
        )
    
    # Extract the properties from the resource for table columns
    # TODO - This needs error handling, currently a bad resource name will lead to a table still being created.
    [string]$PropBlock = ""

    $DscResObj = Get-DscResource $DscResName
    $props = $DscResObj | Select-Object -ExpandProperty Properties

    # Open a connection to SQL and create a 'System.Data.SqlClient.SqlCommand' object
  
    $connection = Open-SqlConnection 
    $command = $connection.CreateCommand()

    # Define a name for the new table based on resource if all succeeded above

    $tablename = $DscResName + "Entries"

    # Create the table with default columns of ID (primary key), partialset this will apply to and a identifier for MOF generation. This names are prefixed to avoid conflicts.

    try
    {
        $command.commandtext = "CREATE TABLE [dbo].[$tablename](
                                [CoreID] [int] IDENTITY(1,1) NOT NULL,
                                   [CorePartialSet] [varchar](255) NOT NULL,
                                [CoreDescription] [varchar](255) NOT NULL,
                                PRIMARY KEY CLUSTERED 
                                (
                                   [CoreID] ASC
                                )WITH (PAD_INDEX = OFF, `
                                STATISTICS_NORECOMPUTE = OFF, `
                                IGNORE_DUP_KEY = OFF, `
                                ALLOW_ROW_LOCKS = ON, `
                                ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
                                ) ON [PRIMARY]"
        $command.ExecuteNonQuery()
    }
    catch
    {
        # The database already exists, at this point we will bail. I may add another switch parameter to update in case 
        # a resource is updated and another property is added.

        Write-Host "$($_.Exception.Message)" -ForegroundColor White -BackgroundColor Red
        return
    }

    # Now add the columns, loop through the properties returned
    foreach($prop in $props)
    {
        # We have to do a bit of string manipulation here as the '[' causes unexpected behaviour in 
        # string comparisons. Just strip them off and wild card to handle arrays.

        switch -wildcard ($($prop.PropertyType).TrimStart('[').TrimEnd(']'))
        {
            "string*" 
            {
                if($prop.Name -notlike "DependsOn")
                {
                    $command.commandtext = "ALTER TABLE $tablename `
                                ADD $($prop.Name) [varchar](max)"
                    $command.ExecuteNonQuery()
                    $PropBlock += $prop.Name + ' = ' + '$row.' + $prop.Name + ';'
                }
            }
            "bool"
            {
                $command.commandtext = "ALTER TABLE $tablename `
                            ADD $($prop.Name) [bit]"
                $command.ExecuteNonQuery()
                $PropBlock += $prop.Name + ' = ' + '$row.' + $prop.Name + ';'
            }
            "UInt32*"
            {
                $command.commandtext = "ALTER TABLE $tablename `
                            ADD $($prop.Name) [int]"
                $command.ExecuteNonQuery()
                $PropBlock += $prop.Name + ' = ' + '$row.' + $prop.Name + ';'
            }
         }
    }

    # Start the ConfigBlock which will be saved to the DSCResource Table in order to build MOFs
    $ConfigBlock = 'foreach($row in $' + $tablename + ') { ' + $DscResName + ' $row.CoreDescription {' + $PropBlock + '}}'
    
  
    $command.commandtext = "INSERT INTO DSCResources (ResourceName,ResourceModule,ConfigBlock) `
                            VALUES('{0}','{1}','{2}')" -f
                            $DscResName,$DscResObj.ModuleName,$ConfigBlock

    # Send Command

    $command.ExecuteNonQuery()
    
    # Clean up connection
    Close-SQLConnection -connection $connection
} 

# Initialize-Table is a help function that sends the SELECT query to the SQL server and populates a DataTable

function Initialize-Table
{
    [CmdletBinding()]
    param (
        [object]$connection,
        [string]$query
    )

    # Verbose output for test

    Write-Verbose "Populating table from query '$query'"

    # Create command from passed in connection, assign the query and execute.

    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $results = $command.ExecuteReader()

    # Save the results to a table to return to the caller

    $table = new-object “System.Data.DataTable”
    $table.Load($results)
    
    # Troubleshooting - this will be removed at some point but was intended to verify data being returned.

    Write-Verbose "Row Count from table in Initialize-Table is $($table.Rows.Count)"

    return $table
}

function Add-DscChangeRecord
{
    [CmdletBinding()]
    param (
        [object]$connection,
        [string]$user,
        [string]$operation,
        [string]$description,
        [string]$date

    )

    $command = $connection.CreateCommand()

    # T-SQL INSERT INTO string
 
    $command.commandtext = "INSERT INTO ChangeLog (Name,Operation,Description,Date) `
                            VALUES('{0}','{1}','{2}','{3}')" -f
                            $user,$operation,$description,$date

    # Send Command

    $command.ExecuteNonQuery()

}

function Open-DSCSettings
{

    [CmdletBinding()]
    param (
        [object]$connection,
        [parameter(mandatory)]
        [string]$ResourceType
    )
    
    Add-type -AssemblyName System.Windows.Forms

    [System.Windows.Forms.Application]::EnableVisualStyles()
    $form1 = New-Object 'System.Windows.Forms.Form'
    $datagridview1 = New-Object 'System.Windows.Forms.DataGridView'
    $buttonOK = New-Object 'System.Windows.Forms.Button'
    $buttonCancel = New-Object 'System.Windows.Forms.Button'
    $InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
    $DGVhasChanged = $false
    #$connStr = "Server=$Instance;Database=$Database;Integrated Security=True"
    
    $form1_Load = {
        $connection = Open-SqlConnection
        $cmd = $connection.CreateCommand()
        $cmd.CommandText = "SELECT * FROM $ResourceType" + "Entries"

        $script:adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
        $dt = New-Object System.Data.DataTable
        $script:adapter.Fill($dt)
        $datagridview1.DataSource = $dt
        $cmdBldr = New-Object System.Data.SqlClient.SqlCommandBuilder($adapter)
    }
    
    $buttonOK_Click = {
        if ($script:DGVhasChanged -and [System.Windows.Forms.MessageBox]::Show('Do you wish to save?', 'Data Changed', 'YesNo')) {
            $script:adapter.Update($datagridview1.DataSource)
        }
    }
    
    $datagridview1_CurrentCellDirtyStateChanged = {
        $script:DGVhasChanged = $true
    }

    $Form_StateCorrection_Load ={
        $form1.WindowState = $InitialFormWindowState
    }
        
    $form1.SuspendLayout()

    
    ## Create the button panel to hold the OK and Cancel buttons
    $buttonPanel = New-Object Windows.Forms.Panel
    $buttonPanel.Size = New-Object Drawing.Size @(400,40)
    $buttonPanel.Dock = "Bottom"
 
    ## Create the Cancel button, which will anchor to the bottom right
    $cancelButton = New-Object Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.DialogResult = "Cancel"
    $cancelButton.Top = $buttonPanel.Height - $cancelButton.Height - 10
    $cancelButton.Left = $buttonPanel.Width - $cancelButton.Width - 10
    $cancelButton.Anchor = "Right"
 
    ## Create the OK button, which will anchor to the left of Cancel
    $okButton = New-Object Windows.Forms.Button
    $okButton.Text = "Ok"
    $okButton.DialogResult = "Ok"
    $okButton.Top = $cancelButton.Top
    $okButton.Left = $cancelButton.Left - $okButton.Width - 5
    $okButton.Anchor = "Right"
    $okButton.add_Click($buttonOK_Click)
    
    ## Add the buttons to the button panel
    $buttonPanel.Controls.Add($okButton)
    $buttonPanel.Controls.Add($cancelButton)

    # form1
    $form1.Controls.Add($datagridview1)
    $form1.Controls.Add($buttonPanel)
    $form1.AcceptButton = $okButton
    $form1.CancelButton = $cancelButton
    $form1.ClientSize = '646, 374'
    $form1.FormBorderStyle = 'Sizable'
    $form1.MaximizeBox = $False
    $form1.MinimizeBox = $False
    $form1.Name = 'form1'
    $form1.StartPosition = 'CenterScreen'
    $form1.Text = 'Form'
    $form1.add_Load($form1_Load)

    $datagridview1.Anchor = 'Top, Bottom, Left, Right'
    $datagridview1.ColumnHeadersHeightSizeMode = 'AutoSize'
    $datagridview1.Location = '13, 13'
    $datagridview1.Name = 'datagridview1'
    $datagridview1.Size = '621, 309'
    $datagridview1.TabIndex = 1
    $datagridview1.add_CurrentCellDirtyStateChanged($datagridview1_CurrentCellDirtyStateChanged)

    $buttonOK.Anchor = 'Bottom, Right'
    $buttonOK.DialogResult = 'OK'
    $buttonOK.Location = '559, 339'
    $buttonOK.Name = 'buttonOK'
    $buttonOK.Size = '75, 23'
    $buttonOK.TabIndex = 0
    $buttonOK.Text = '&OK'
    $buttonOK.UseVisualStyleBackColor = $True
    $buttonOK.add_Click($buttonOK_Click)
    $form1.ResumeLayout()

    $InitialFormWindowState = $form1.WindowState
    $form1.add_Load($Form_StateCorrection_Load)
    $form1.ShowDialog()
    
}

function Get-DscSettings
{
    [CmdletBinding()]
    param (
        [string]$category
    )

    $dbtables = @{"Registry" = "RegistryEntries"; `
                  "Audit" = "AuditPolicy"; `
                  "Services" = "ServiceEntries"; `
                  "ChangeLog" = "ChangeLog";
                  "File" = "FileEntries";
                  "WindowsFeatureSet" = "WindowsFeatureSetEntries"}

    if(!$dbtables.Contains($category))
    {
        Write-Host "Unknown category, please use 'Registry | Services | Audit | File | WindowsFeatureSet | ChangeLog"
        return
    }

    $connection = Open-SqlConnection 

    #Assign the query value and send
    $query = "SELECT * FROM $($dbtables.$category)"
    $table = Initialize-Table -connection $connection -query $query

    # Troubleshooting
    Write-Verbose "Row Count from table in Get-DscSettings is $($table.Rows.Count)"

    Close-SQLConnection $connection

    return $table

}

function Open-SqlConnection
{
    [CmdletBinding()]
    param (
        [string]$computername = "anwillx1",
        [string]$database = "DSC"
    )

    $connectionString = "Server=$computername;Database=$database;trusted_connection=true;"
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString

    Write-Verbose "Opening Connection $($connection.ConnectionString)"
    $connection.Open()

    return $connection

}

function Close-SqlConnection
{
    [CmdletBinding()]
    param (
        [object]$connection
    )

    Write-Verbose "Closing Connection $($connection.ConnectionString)"
    $connection.Close()
}

function New-DscMOF
{
    [CmdletBinding()]
    param (
        [string]$PartialSet,
        [string]$ComputerName = "localhost"
        )

        $dbtables = Get-DSCDBtables

        $connection = Open-SqlConnection 

        foreach($entry in $dbtables)
        {
            # TODO, currently allowing wildcard searches 

            $query = "SELECT * FROM $($entry.Name) WHERE CorePartialSet LIKE '%$partialset%'"
            Set-Variable -Name $($entry.Name) -Value (Initialize-Table -connection $connection -query $query)
        }

        # We've built variables, now get the string for use in Config Script. For now add everything in the DB, this will be changed to only those resources we
        # have entries for.

        $query = "SELECT * FROM DSCResources"
        $dscresources = Initialize-Table -connection $connection -query $query
        Close-SQLConnection -connection $connection

        # Add strings for Config, we build an array of string that will make up the script.

        $MyConf = @()
        $MyConf += "Configuration MyStandards{"
        $MyConf += 'Import-DscResource -ModuleName PSDesiredStateConfiguration'

        # Add other modules

        foreach($row in $dscresources)
        {
            if($row.ResourceModule -notlike "PSDesiredStateConfiguration")
            {
                $MyConf += "Import-DscResource -ModuleName $($row.ResourceModule)"
            }
        }

        $MyConf += "node $ComputerName{"

        # Add the ConfigBlock for each resource

        foreach($row in $dscresources)
        {
            $MyConf += $row.ConfigBlock
        }

        # Close the statements and add the call, there may be a need to add parameters here.

        $MyConf += '}}'
        $MyConf += "MyStandards"

        # Build the Config from the string array

        $MyConfScript = ""
        $MyConf | ForEach-Object {$MyConfScript += $_.ToString() + "`n"}

        $MyConfScript = $ExecutionContext.InvokeCommand.NewScriptBlock($MyConfScript)

        try
        {
            & $MyConfScript
        }
        catch [System.UnauthorizedAccessException]
        {
            Write-Host "$($_.Exception.Message)" -ForegroundColor White -BackgroundColor Red
            Write-Host "Please ensure you are running with Administrator privileges" -ForegroundColor White -BackgroundColor Red
            return
        }
        catch
        {
            Write-Host "$($_.Exception.Message)" -ForegroundColor White -BackgroundColor Red
            return
        }
}

Export-ModuleMember -Function Get-DscSettings,`
                              Add-DscChangeRecord,`
                              New-DscMOF,`
                              Initialize-Table,`
                              Open-SqlConnection,`
                              Close-SqlConnection, `
                              New-DBTableFromResource,`
                              Get-DSCDBTables, `
                              Open-DSCSettings