
<#PSScriptInfo

.VERSION 1.0

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


# Finds users who expire that day and disables them. Also clears their expired state.
Import-Module Logging
$ErrorActionPreference = 'Continue'

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Log File Info
$LM = New-LogManager

$scriptName = $(Get-ChildItem $PSCommandPath).BaseName
$sLogPath = "\\k4-scriptserv\logs$\$scriptName\"
if (!$(Test-Path $sLogPath)) {
    Write-Host "Making Folder $sLogPath"
    New-Item -Path $sLogPath -ItemType Directory
}
$sLogName = "$(get-date -Format MM-dd-yy).log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

New-FileLogger -Path $sLogFile -logLevel Info -LogManager $LM
New-FileLogger -Path $sLogPath -logLevel Error -LogManager $LM
New-ConsoleLogger -logLevel Info -LogManager $LM


$expireingUsers = Get-ADUser -Filter { AccountExpirationDate -lt $today } -Properties AccountExpirationDate |select-object Name, SamAccountName, AccountExpirationDate

foreach ($user in $expireingUsers) {

    # Disable Account
    try {

        disable-adaccount -identity $user.samaccountname
        New-Log -LogManager $LM -message "Successfully disabled $($user.SamAccountName)"

    } catch {

        New-Log -LogManager $LM -message "Error Disabling $($user.SamAccountName) - $($_.exception.message)"

    }

    # Clear Experation Date
    try {

        clear-adaccountexpiration -identity $user.samaccountname
        New-Log -LogManager $LM -message "Successfully cleared account experation for $($user.SamAccountName)"

    } catch {

        New-Log -LogManager $LM -message "Error clearing experation for $($user.SamAccountName) - $($_.exception.message)"

    }

    # Set description to show how it was disabled.
    try {

        Set-ADUser -identity $user.samaccountname -Description "Expired $today - K4-ScriptServ"
        New-Log -LogManager $LM -message "Successfully changed description for $($user.SamAccountName)"

    } catch {

        New-Log -LogManager $LM -message "Error setting discription for $($user.SamAccountName) - $($_.exception.message)"

    }
}
