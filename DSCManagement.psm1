# Cleans up the global variables used to store rows. Called from New-DscMOF after success or fail.

function Remove-Artefacts
{
    Get-Variable "newDSC*" | Remove-Variable -Scope Global
}

# Creates the table required for DSC Resource metadata, probably not needed unless creating new DB.

function New-DBTableForDSCMetadata
{
    [CmdletBinding()]
    param (
        [object]$connection
    )

    $command = $connection.CreateCommand()
    
    try
    {
        $command.commandtext = "CREATE TABLE [dbo].[DSCResources](
                                [ResourceName] [varchar](max) NOT NULL,
                                [ResourceModule] [varchar](max) NOT NULL,
                                [ResourceModuleVersion] [varchar](max) NOT NULL,
                                [ResourceType] [varchar](max) NOT NULL,
                                [ConfigBlock] [varchar](max) NOT NULL
                                ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]"
        $command.ExecuteNonQuery()
    }
    catch
    {
        # The database already exists, at this point we will bail. I may add another switch parameter to update in case 
        # a resource is updated and another property is added.

        Write-Host "$($_.Exception.Message)" -ForegroundColor White -BackgroundColor Red
        return
    }
}
# Function: New-DBTableFromResource
#
# New-DBTableFromResource can be used to quickly create tables based on the properties of the DSC Resource.
# Any further alterations can be made directly through SSMS. 

function New-DBTableFromResource
{
   [CmdletBinding()]
    param (
        [string]$DscResName,
        [object]$connection
        )
    
    # Extract the properties from the resource for table columns
    # TODO - This needs error handling, currently a bad resource name will lead to a table still being created.
    [string]$PropBlock = ""

    if(($DscResObj = Get-DscResource $DscResName).Count -gt 1)
    {
        Write-Host "There appears to be more than one version of this resource present." -BackgroundColor Red
        $DscResObj

        $version = Read-Host "Please enter the version you wish to use: "
        $DscResObj = $DscResObj | Where-Object {$_.Version -like $version}
    }    

    $props = $DscResObj | Select-Object -ExpandProperty Properties

    # Open a connection to SQL and create a 'System.Data.SqlClient.SqlCommand' object
  
    if(!$connection)
    {
        $connection = Open-SqlConnection
    }
    $command = $connection.CreateCommand()

    # Define a name for the new table based on resource if all succeeded above

    $tablename = $DscResName + "Entries"

    # Create the table with default columns of ID (primary key), partialset this will apply to and a identifier for MOF generation. This names are prefixed to avoid conflicts.

    try
    {
        $command.commandtext = "CREATE TABLE [dbo].[$tablename](
                                [CoreID] [int] IDENTITY(1,1) NOT NULL,
                                [CorePlatform] [varchar](255) NOT NULL,
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

        # SQL contains some keywords which cannot be used for columns. Update the array below in case 
        # these are encountered. W

        $SqlKeyWords = @('Key','Table','Index','Database')

        # Check if $prop.Name is considered a keyword and change.
        if($SqlKeyWords.Contains($prop.Name)){$prop.Name = $prop.Name+"Name"}

        # Determine type and add to table definition
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
    
    # Fixup the Config Block so any reserved SQL keyword is stored correctly as it's DSC resource property name.
    foreach($word in $SqlKeyWords)
    {
        $ConfigBlock = $ConfigBlock.Replace($word + "Name =",$word + ' =')
    }

    # Update DSCResource metadata table
    $command.commandtext = "INSERT INTO DSCResources (ResourceName,ResourceModule,ResourceModuleVersion,ResourceType,ConfigBlock) `
                            VALUES('{0}','{1}','{2}','{3}','{4}')" -f
                            $DscResName,$DscResObj.ModuleName,$DscResObj.Version.ToString(),$DscResObj.ResourceType,$ConfigBlock

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
        [string]$Resource
    )

    $connection = Open-SqlConnection 

    # Target table based on user input - DB standard for table names is '<DscRescoureName>Entries'

    $requiredTable = $Resource + "Entries"

    # Create an array of available tables

    $dbTables = Get-DscDBTables -connection $connection

    # If a non-existent table has been specified then display what is available (drops the 'Entries' part of the table name)

    if(!$dbtables.Name.ToUpper().Contains($requiredTable.ToUpper()))
    {
        Write-Host "`nUnknown resource, tables categories are available:`n"
        $dbTables.Name.Replace('Entries','')
        return
    }
    
	# DSC Settings - Uses a PowerShell Form Object
    Add-type -AssemblyName System.Windows.Forms

    [System.Windows.Forms.Application]::EnableVisualStyles()
    $form1 = New-Object 'System.Windows.Forms.Form'
    $datagridview1 = New-Object 'System.Windows.Forms.DataGridView'
    $buttonOK = New-Object 'System.Windows.Forms.Button'
    $InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
    $DGVhasChanged = $false

    # Load the form and populate with selected table data

    $form1_Load = {
        $connection = Open-SqlConnection
        $cmd = $connection.CreateCommand()
        $cmd.CommandText = "SELECT * FROM $Resource" + "Entries"

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
    $form1.Text = $ResourceType + "Entries Table Data"
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
	
	# Display for the Form
    $form1.ShowDialog()
    
}
# Help function to obtain a list of tables currently present in the database (Exported)
function Get-DscDBTables
{

    [CmdletBinding()]
    param (
        [object]$connection
    )

    $connection = Open-SqlConnection

    $query = "SELECT Name FROM Sys.Tables WHERE Name LIKE '%Entries'"
    $table = Initialize-Table -connection $connection -query $query

    return $table
}

# Get DSCSettings from the database
# TODO string comparisons are not great. Needs some variable work.

function Get-DscSettings
{
    [CmdletBinding()]
    param (
        [string]$Resource,
        [switch]$ListDBTables
    )

    $connection = Open-SqlConnection 

    # Target table based on user input - DB standard for table names is '<DscRescoureName>Entries'

    $requiredTable = $Resource + "Entries"

    # Create an array of available tables

    $dbTables = Get-DscDBTables -connection $connection

    if($PSBoundParameters.ContainsKey("ListDBTables"))
    {
        Write-Output "`nThe following DSC Resources have entries in the database:"
        $dbTables
        return
    }

    # If a non-existent table has been specified then display what is available (drops the 'Entries' part of the table name)

    if(!$dbtables.Name.ToUpper().Contains($requiredTable.ToUpper()))
    {
        Write-Host "`nUnknown resource, tables categories are available:`n"
        $dbTables.Name.Replace('Entries','')
        return
    }

    # A valid table has been requested, assign the query value and send

    $query = "SELECT * FROM $requiredTable"
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
        [string]$computername = ".\sqlexpress",
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

# Function: Update-ConfigBlock
#
# This will take a base configuration block and remove the redundant entries based on the columns
# used in the DataRow record. 
#
# For Example, for the record below..
#
#    Name                 : All
#    Ensure               : 
#    IncludeAllSubFeature : True
#    LogPath              : C:\Logs
#    Source               : 
#
# We will change this ConfigBlock:
# 
# {Name = $row.Name;Ensure = $row.Ensure;IncludeAllSubFeature = $row.IncludeAllSubFeature;LogPath = $row.LogPath;Source = $row.Source;}}
#
# To this:
#
# {Name = $row.Name;IncludeAllSubFeature = $row.IncludeAllSubFeature;LogPath = $row.LogPath;}}
#
# This ensures the unused columns of 'Ensure' and 'Source' are not referenced during COnfiguration script compile.
#
function Update-ConfigBlock
{
    [CmdletBinding()]
    param (
        [string]$dbTable,
        [string]$ConfigBlock,
        [string]$Platform
    )

    # Open a connection to the DB to return records and run the query.

    $connection = Open-SqlConnection 
    $query = "SELECT * FROM $dbTable WHERE CorePlatform LIKE '%$Platform%'"
    $TableEntries = @(Initialize-Table -connection $connection -query $query)

    # No records found, as we've called this function to assign to a variable all output is returned
    # See https://msdn.microsoft.com/powershell/reference/5.1/Microsoft.PowerShell.Core/about/about_Return 
    # for more details on PowerShell returns. For now I place a # in front so it ends up as a comment in the
    # Config Script.

    if($TableEntries.Count -eq 0)
    {
        Write-Output "#No records found for $dbTable"
        return
    }

    # We have data so extract the Table Columns so we can count the number and reference the names 

    [System.Data.DataTable] $table = $TableEntries[0].Table

    # prefix name for the variables used in the script. 

    $tablePrefix = "newDSC$dbTable"

    # Create a hash table with column names to bits, this will be checked with the bitmask to determine those column names in use
    # Raising 2 to the power of i$ (starting at 0) will provide the Keys as bit values.

    $columnNames = @{}
    for($i = 0;$i -lt $table.Columns.Count;$i++)
    {
        $columnNames.Add([Math]::Pow(2, $i),$table.Columns[$i].ColumnName)
    }

    # Check each column in the DataRow and build a bitmask representing those in use.

    foreach($row in $TableEntries)
    {
        
        $bitMaskValue = 0
        for($i = 0;$i -lt $table.Columns.Count;$i++)
        {
            if(!$row.IsNull($i))
            {
                # Need to build bitmask of populated columns
                $bitMaskValue = $bitMaskValue + [Math]::Pow(2, $i)
            }
        }

        # Crearte a variable for each column 'in use' variation. Variables may already be present from previous run, if so 
        # clear, if not create. 

        # TODO clean up variables

        if(!(Test-Path Variable:\$($tablePrefix + $bitMaskValue)))
        {
            New-Variable -Name ($tablePrefix + $bitMaskValue) -Value @() -Scope Global
        }

        # Add the row to the correct array based on columns in use.

        (Get-Variable -Name ($tablePrefix + $bitMaskValue)).Value += $row
    }

    # We should now have all the values placed into new tables based on the columns used. Output a new $configblock to an array
    # that will then be written to the in memory configuration script

    $configBlockArray = @()

    foreach($newVariable in (Get-Variable -Name "newDSC$dbTable*"))
    {
        # We need to assign the $ConfigBlock passed in to a new varaible to avoid clashes.
        
        $newBlock = $ConfigBlock
        $newBlock = $newBlock.Replace($dbTable,"$($newVariable.Name)")

        # Extract the bitmask from the end of the table name so we can use the value to evalate what needs to be removed from
        # the configBlock string. The column names not in use will be added to 

        $bitmask = $newVariable.Name.Replace("$tablePrefix","")
        $columnsToRemove = $columnNames.Keys | Where-Object {!($_ -band $bitmask)} | Foreach-Object {$columnNames.Get_Item($_)}
        
        # Loop around the values to remove. This is quite straightforward as the text pattern is fixed when we wrote to DB.

        foreach($column in $columnsToRemove)
        {
            # We will need a special case here where a known keyword needs to be removed.
            # This string pattern is based on what is written into the DSCResources table

            $newBlock = $newBlock.Replace("$column = " + '$row' + ".$column;","")
        }

        # Add the new block to the array and loop back around if needed.

        $configBlockArray += $newBlock
    }

    # Return the strings for inclusion in the configuration script.

    return $configBlockArray
}



function New-DscMOF
{
    [CmdletBinding()]
    param (
        [string]$Platform,
        [string]$ComputerName = "localhost",
        [string]$ConfigName = "MySettings"
        )

        $connection = Open-SqlConnection 

        # DSC Resource metadata is stored in the DSCResources table.  Read all of the settings from here so we can look 
        # to build configuration blocks

        $query = "SELECT * FROM DSCResources"
        $dscresources = Initialize-Table -connection $connection -query $query
        Close-SQLConnection -connection $connection

        # We will build an array of strings that will make up the script. This will then be executed once complete to produce the .MOF

        $MyConf = @()
        $MyConf += "Configuration MySettings{"
        $MyConf += 'Import-DscResource -ModuleName PSDesiredStateConfiguration'

        # Add modules used, this will not be reflected in final MOF if no settings for a particular resource are required.

        foreach($row in $dscresources)
        {
            if($row.ResourceModule -notlike "PSDesiredStateConfiguration")
            {
                $MyConf += "Import-DscResource -ModuleName $($row.ResourceModule)" + " -ModuleVersion $($row.ResourceModuleVersion)"
            }
        }

        # Write the compunter name, defaults to localhost.

        $MyConf += "node $ComputerName{"

        # Add the ConfigBlock for each resource, this needs to review what columns are in use and build some globals for reference.

        foreach($row in $dscresources)
        {
            $dbTableName = "$($row.ResourceName)Entries"
            $MyConf += Update-ConfigBlock -dbTable $dbTableName -ConfigBlock $row.ConfigBlock -Platform $Platform
        }

        # Close the statements and add the call, there may be a need to add parameters here.

        $MyConf += '}}'
        $MyConf += "MySettings"

        # Build the Config from the string array and add some line breaks.

        $MyConfScript = ""
        $MyConf | ForEach-Object {$MyConfScript += $_.ToString() + "`n"}

        $MyConfScript = $ExecutionContext.InvokeCommand.NewScriptBlock($MyConfScript)

        try
        {
            & $MyConfScript -Verbose
        }
        catch [System.UnauthorizedAccessException]
        {
            Write-Host "$($_.Exception.Message)" -ForegroundColor White -BackgroundColor Red
            Write-Host "Please ensure you are running with Administrator privileges" -ForegroundColor White -BackgroundColor Red
            Remove-Artefacts
            return
        }
        catch
        {
            Write-Host "$($_.Exception.Message)" -ForegroundColor White -BackgroundColor Red
            Remove-Artefacts
            return
        }

        # Clean up variables to avoid issues on subsequent runs

        Remove-Artefacts   
    
}

Export-ModuleMember -Function Get-DscSettings,`
                              New-DscMOF,`
                              Initialize-Table,`
                              Open-SqlConnection,`
                              Close-SqlConnection, `
                              New-DBTableFromResource,`
                              Open-DSCSettings,`
                              New-DBTableForDSCMetadata,`
                              Get-DscDBTables