properties {
    $OutputPath = Join-Path -Path .\ -ChildPath Output
    $configName = "DEU.Config"
    $ScriptName = "disable-expired-users"
    $ScriptDIR = Join-Path -Path $OutputPath -ChildPath $ScriptName

}

task default -depends clean, build, test

task Test {
    Write-Host "Tests not yet implemented"
}

task Clean {
    if (Test-Path -Path "$OutputPath") {
        Remove-Item -Path $OutputPath -Recurse
        New-Item -Path .\ -ItemType Directory -Name "Output" | Out-Null
        New-Item -Path $OutputPath -Name $ScriptName -ItemType Directory | Out-Null
    } else {
        New-Item -Path .\ -ItemType Directory -Name "Output" | Out-Null
        New-Item -Path $OutputPath -Name $ScriptName -ItemType Directory | Out-Null
    }

}

task Build -depends Clean {
    $Functions = Get-ChildItem ".\SRC\Functions\"

    Copy-Item -Path ".\SRC\$ScriptName.ps1" -Destination $ScriptDIR
    Copy-Item -Path ".\SRC\$configName.psd1" -Destination $ScriptDIR
    
    $Content = Get-Content -Path .\src\LogConfig.ps1 | Out-String

    $Content + (Get-Content -Path "$ScriptDIR\$ScriptName.ps1" | Out-String) | Set-Content "$ScriptDIR\$ScriptName.ps1"

    # Export Public Functions
    foreach ($Function in $Functions) {
        # Get the content of the function file.
        $Content = Get-Content -Path $Function.FullName | Out-String
        # Add the content of the function file to the front of the script. 
        $Content + (Get-Content -Path "$ScriptDIR\$ScriptName.ps1" | Out-String) | Set-Content "$ScriptDIR\$ScriptName.ps1"
    }
    # Get the contents of the script properties.
    $Content = Get-Content -Path .\src\ScriptProperties.ps1 | Out-String
    # Add the content to the front of the script. 
    $Content + (Get-Content -Path "$ScriptDIR\$ScriptName.ps1" | Out-String) | Set-Content "$ScriptDIR\$ScriptName.ps1"

}

task Publish -depends Build, Test {
    Publish-Script -Path "$ScriptDIR\$ScriptName.ps1" -Repository "MPSPSRepo"
}

task Exe -depends Build, Test {
    
}
