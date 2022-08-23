
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
