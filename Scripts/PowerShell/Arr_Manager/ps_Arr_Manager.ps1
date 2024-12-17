$ARRPrograms = @(
    "C:\ProgramData\Sonarr\bin\Sonarr.exe",
    "C:\ProgramData\Radarr\bin\Radarr.exe",
    "C:\ProgramData\Prowlarr\bin\Prowlarr.exe",
    "C:\Program Files\SABnzbd\SABnzbd.exe"
)

function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    return $currentUser.IsInRole($adminRole)
}

function Manage-ARRProgram {
    param (
        [string]$ProgramPath,
        [string]$Action
    )

    $programName = [System.IO.Path]::GetFileNameWithoutExtension($ProgramPath)
    $process = Get-Process -Name $programName -ErrorAction SilentlyContinue

    switch ($Action) {
        'Start' {
            if ($process) {
                Write-Output "$programName was already running - closed it, then started it"
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            } else {
                Write-Output "$programName was not running, started it"
            }
            Start-Process -FilePath $ProgramPath -Verb RunAs
        }
        'Stop' {
            if ($process) {
                Write-Output "$programName was running, closed it"
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            } else {
                Write-Output "$programName is already closed"
            }
        }
    }
}

function Open-ARRWebInterfaces {
    Write-Output "Opening Radarr web interface at http://localhost:7878/"
    Start-Process "http://localhost:7878/"

    Write-Output "Opening Sonarr web interface at http://localhost:8989/"
    Start-Process "http://localhost:8989/"

    Write-Output "Opening Prowlarr web interface at http://localhost:9696/"
    Start-Process "http://localhost:9696/"

    Write-Output "Opening SABnzbd web interface at http://127.0.0.1:8080/sabnzbd/"
    Start-Process "http://127.0.0.1:8080/sabnzbd/"
}

# Ensure script runs as administrator
if (-Not (Test-Administrator)) {
    Write-Host "Elevating..."
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# Menu for ARR management
do {
    Clear-Host

    Write-Host "================================="
    Write-Host "====== ARR Program Manager ======"
    Write-Host "================================="
    Write-Host "1. Start all ARR programs"
    Write-Host "2. Close all ARR programs"
    Write-Host "3. Open all web interfaces"
    Write-Host "4. Exit"
    Write-Host "================================="

    $choice = Read-Host "Enter your choice (1-4)"
    Write-Host ""
    switch ($choice) {
        1 { 
            foreach ($programPath in $ARRPrograms) { 
                Manage-ARRProgram -ProgramPath $programPath -Action 'Start' 
            } 
        }

        2 { 
            foreach ($programPath in $ARRPrograms) { 
                Manage-ARRProgram -ProgramPath $programPath -Action 'Stop' 
            } 
        }

        3 { Open-ARRWebInterfaces }

        4 { exit }
        default { Write-Host "Invalid Option" }
    }

    Write-Host ""
    Read-Host "Complete! Press Enter"
} while ($true)
