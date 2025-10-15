@{
    Rules = @{
        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
        }
        
        PSPlaceCloseBrace = @{
            Enable = $true
            NewLineAfter = $false
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore = $false
        }
        
        PSUseConsistentIndentation = @{
            Enable = $true
            Kind = 'space'
            PipelineIndentation = 'IncreaseIndentationAfterEveryPipeline'
            IndentationSize = 4
        }
        
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckSeparator = $true
            CheckParameter = $false
        }
        
        PSAlignAssignmentStatement = @{
            Enable = $true
            CheckHashtable = $true
        }
        
        PSUseCorrectCasing = @{
            Enable = $true
        }
        
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }
        
        PSAvoidUsingPlainTextForPassword = @{
            Enable = $true
        }
        
        PSAvoidUsingConvertToSecureStringWithPlainText = @{
            Enable = $true
        }
        
        PSUseShouldProcessForStateChangingFunctions = @{
            Enable = $true
        }
        
        PSUseSingularNouns = @{
            Enable = $true
        }
        
        PSUseApprovedVerbs = @{
            Enable = $true
        }
        
        PSReservedCmdletChar = @{
            Enable = $true
        }
        
        PSReservedParams = @{
            Enable = $true
        }
        
        PSMissingModuleManifestField = @{
            Enable = $true
        }
        
        PSUseToExportFieldsInManifest = @{
            Enable = $true
        }
        
        PSAvoidDefaultValueSwitchParameter = @{
            Enable = $true
        }
        
        PSAvoidDefaultValueForMandatoryParameter = @{
            Enable = $true
        }
        
        PSAvoidUsingDoubleQuotesForConstantString = @{
            Enable = $true
        }
    }
    
    ExcludeRules = @(
        'PSUseBOMForUnicodeEncodedFile'
    )
    
    IncludeDefaultRules = $true
}