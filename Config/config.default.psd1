@{
    # Server connection settings
    DefaultServer     = '.\SQLEXPRESS'
    DefaultDatabase   = 'DSC'
    
    # Connection timeout in seconds
    ConnectionTimeout = 30
    
    # Command timeout in seconds
    CommandTimeout    = 300
    
    # Enable SQL connection pooling
    Pooling          = $true
    
    # Maximum pool size
    MaxPoolSize      = 100
    
    # Minimum pool size
    MinPoolSize      = 5
    
    # Logging settings
    LogLevel         = 'Information' # None, Error, Warning, Information, Verbose
    LogPath          = $null # If null, uses default module log location
    
    # Table naming convention
    TableSuffix      = 'Entries'
    
    # Core columns that are added to every table
    CoreColumns      = @(
        @{ Name = 'CoreID'; Type = 'int'; Identity = $true; PrimaryKey = $true }
        @{ Name = 'CorePlatform'; Type = 'varchar(255)'; Required = $true }
        @{ Name = 'CoreDescription'; Type = 'varchar(255)'; Required = $true }
    )
    
    # SQL Keywords that need special handling
    SqlKeywords      = @('Key', 'Table', 'Index', 'Database', 'User', 'Group', 'Order', 'Select')
    
    # Default base platform for inheritance
    BasePlatform     = 'BaseOS'
}