# Finds users who expire that day and disables them. Also clears their expired state. 
$log = "$PSScriptRoot\disabled-users.log"

function Log-Item {
    param(
        [string]$Logfile,
        [string]$message    
    )
    $test_logfile = Test-Path $Logfile

    if($test_logfile){
        Add-Content $Logfile "$(get-date -UFormat %R),$message"
    } else {
        Set-Content $Logfile "Timestamp,Message"
    }
}


$today = Get-Date

$expireingUsers = Get-ADUser -Filter { AccountExpirationDate -lt $today } -Properties AccountExpirationDate |select Name,SamAccountName,AccountExpirationDate

foreach($user in $expireingUsers){
    
    # Disable Account
    try{

        disable-adaccount -identity $user.samaccountname
        Log-Item -Logfile $log -message "Successfully disabled $($user.SamAccountName)"

    }catch{
        
        Log-Item -Logfile $log -message "Error Disabling $($user.SamAccountName) - $($_.exception.message)"

    }

    # Clear Experation Date
    try{

        clear-adaccountexpiration -identity $user.samaccountname 
        Log-Item -Logfile $log -message "Successfully cleared account experation for $($user.SamAccountName)"

    }catch{
        
        Log-Item -Logfile $log -message "Error clearing experation for $($user.SamAccountName) - $($_.exception.message)"

    }

    # Set description to show how it was disabled. 
    try{
        
        Set-ADUser -identity $user.samaccountname -Description "Expired $today - K4-ScriptServ"
        Log-Item -Logfile $log -message "Successfully changed description for $($user.SamAccountName)"

    }catch{
        
        Log-Item -Logfile $log -message "Error setting discription for $($user.SamAccountName) - $($_.exception.message)"

    }
}