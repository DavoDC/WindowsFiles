function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    return $currentUser.IsInRole($adminRole)
}

function Get-EthernetAdapterStatus {
    $adapter = Get-NetAdapter | Where-Object { $_.Name -eq "Ethernet" }
    return $adapter.Status -eq "Up"
}

function Toggle-EthernetAdapter {
    if (Get-EthernetAdapterStatus) {
        Write-Output "Disabling Ethernet..."
        Disable-NetAdapter -Name "Ethernet" -Confirm:$false
    } else {
        Write-Output "Enabling Ethernet..."
        Enable-NetAdapter -Name "Ethernet" -Confirm:$false
    }
}

function Fix-IPConfiguration {
    Write-Output "Flushing DNS cache..."
    ipconfig /flushdns | Out-Null

    Write-Output "Registering DNS..."
    ipconfig /registerdns | Out-Null

    Write-Output "Releasing IP address..."
    ipconfig /release | Out-Null

    Write-Output "Renewing IP address..."
    ipconfig /renew | Out-Null

    Write-Output "Resetting Winsock..."
    netsh winsock reset | Out-Null
}

function Print-EthernetAdapterStatus {
    $status = "Disabled"
    if (Get-EthernetAdapterStatus) {
        $status = "Enabled"
    }
    Write-Output "Ethernet Adapter Status: $status"
}

function Do-Both {
    Fix-IPConfiguration
    Toggle-EthernetAdapter
    Toggle-EthernetAdapter
}

# EXECUTION
if (-Not (Test-Administrator)) {
    Write-Host "Elevating..."
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

do {
    Clear-Host

    Write-Host "=============================="
    Write-Host "======= Internet Fixer ======="
    Write-Host "=============================="
    Write-Host "1. Cycle Ethernet Adapter"
    Write-Host "2. Toggle Ethernet Adapter"
    Write-Host "3. Print Ethernet Adapter Status"
    Write-Host "4. Fix IP Configuration"
    Write-Host "5. Cycle Ethernet Adapter AND Fix IP Configuration"
    Write-Host "6. Exit"
    Write-Host "=============================="

    $choice = Read-Host "Enter your choice (1-6)"
    Write-Host ""
    switch ($choice) {
        1 { Toggle-EthernetAdapter; Toggle-EthernetAdapter }
        2 { Toggle-EthernetAdapter }
        3 { Print-EthernetAdapterStatus }
        4 { Fix-IPConfiguration }
        5 { Do-Both }
        6 { exit }
        default {  Write-Host "Invalid Option" }
    }

    Write-Host ""
    Read-Host "Complete! Press Enter"
} while ($true)