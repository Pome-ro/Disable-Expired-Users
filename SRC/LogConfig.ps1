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