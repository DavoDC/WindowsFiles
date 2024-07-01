
# Space
Write-Host ""

# Get script folder
$scriptDirectory = $PSScriptRoot
if (-not $scriptDirectory) {
    $scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
}

# Get all files in the folder
$files = Get-ChildItem -Path $scriptDirectory

# Iterate over each file
foreach ($file in $files) {
    
    # If file is a script, skip it
    if ($file.Extension -eq ".ps1") {
        continue
    }

    # Make folder with same name
    $folderPath = Join-Path -Path $file.Directory.FullName -ChildPath $file.BaseName
    New-Item -ItemType Directory -Path $folderPath -Force

    # Move file into folder
    Move-Item -Path $file.FullName -Destination $folderPath

    Write-Host "`nFile moved to: $folderPath`n"
}

Pause