<#
.SYNOPSIS
    Loads and returns the DSCManagement module configuration.

.DESCRIPTION
    Loads configuration from the default config file and any local overrides.
    Returns a merged configuration object with all settings.

.EXAMPLE
    $config = Get-DscModuleConfig
#>
function Get-DscModuleConfig {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $moduleRoot = Split-Path -Parent $PSScriptRoot
    $defaultConfigPath = Join-Path $moduleRoot 'Config\config.default.psd1'
    $localConfigPath = Join-Path $moduleRoot 'Config\config.local.psd1'

    # Load default configuration
    if (Test-Path $defaultConfigPath) {
        $config = Import-PowerShellDataFile -Path $defaultConfigPath
    } else {
        throw "Default configuration file not found: $defaultConfigPath"
    }

    # Override with local configuration if it exists
    if (Test-Path $localConfigPath) {
        $localConfig = Import-PowerShellDataFile -Path $localConfigPath
        foreach ($key in $localConfig.Keys) {
            $config[$key] = $localConfig[$key]
        }
        Write-Verbose "Local configuration loaded from: $localConfigPath"
    }

    return $config
}