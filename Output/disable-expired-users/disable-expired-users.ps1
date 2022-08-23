#----------------------------------------------------------[Script Properties]-----------------------------------------------


<#PSScriptInfo

.VERSION 1.0.2

.GUID 236a52e8-3264-4593-af92-e6fba67b1753

.AUTHOR pomeroyte@mansfieldct.org

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


#>

<#

.DESCRIPTION
 scans ad for expired accounts and sets them to disabled

#>

Param()

#----------------------------------------------------------[Functions]-------------------------------------------------------
#----------------------------------------------------------[Configuration]----------------------------------------------------

$Config = Import-PowershellDataFile -Path "$PSScriptRoot\DEU.Config.psd1"
Import-Module -Name $Config.RequiredModules
$ErrorActionPreference = 'Continue'

#----------------------------------------------------------[Logging]----------------------------------------------------------

$LM = New-LogManager
$scriptName = $(Get-ChildItem $PSCommandPath).BaseName
$sLogPath = Join-Path -Path $Config.logRoot -ChildPath $ScriptName

if (!$(Test-Path $sLogPath)) {
    New-Log -LogManager $LM -Message "Making Folder $sLogPath"
    New-Item -Path $sLogPath -ItemType Directory
}

$sLogName = "$(get-date -Format MM-dd-yy).log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

New-FileLogger -Path $sLogFile -logLevel Info -LogManager $LM
New-FileLogger -Path $sLogFile -logLevel Error -LogManager $LM
New-ConsoleLogger -logLevel Info -LogManager $LM
New-Log -LogManager $LM -Message "Logging Started" -LogLevel Info

#----------------------------------------------------------[Start of Script]-------------------------------------------------

$Today = Get-Date
$expireingUsers = Get-ADUser -Filter { AccountExpirationDate -lt $today } -Properties AccountExpirationDate |select-object Name, SamAccountName, AccountExpirationDate

foreach ($user in $expireingUsers) {

    try {
        # Disable Account
        disable-adaccount -identity $user.samaccountname
        New-Log -LogManager $LM -message "Attempting to disabled $($user.SamAccountName)" -logLevel Info

        # Clear Experation Date
        Set-ADUser -identity $user.samaccountname -Description "Expired $today - K4-ScriptServ"
        New-Log -LogManager $LM -message "Attempting to change description for $($user.SamAccountName)" -logLevel Info
        
        # Move to Disabled Users OU
        Move-ADObject -Identity $user.samaccountname -TargetPath $Config.DisabledOU
        New-Log -LogManager $LM -message "Attempting to move $($user.SamAccountName) to mps/_Mansfield Public Schools/Disabled Objects/User Objects" -logLevel Info

        # Set description to show how it was disabled.
        clear-adaccountexpiration -identity $user.samaccountname
        New-Log -LogManager $LM -message "Attempting to clear account experation for $($user.SamAccountName)" -logLevel Info

    } catch {

        New-Log -LogManager $LM -message "Error processing $($user.SamAccountName)" -logLevel Error
        New-Log -LogManager $LM -message $_.Exception.Message -logLevel Error

    }

}



