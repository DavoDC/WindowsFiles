# Get the current directory
$Path = Get-Location

# Find and list all files in the current directory and its subdirectories
$Files = Get-ChildItem -Path $Path -Recurse -File
Write-Output "Found $($Files.Count) files in $Path"

# Find empty directories and delete them
$EmptyFolders = Get-ChildItem -Path $Path -Recurse -Directory | Where-Object { $_.GetFileSystemInfos().Count -eq 0 }

foreach ($Folder in $EmptyFolders) {
    Write-Output "Deleting empty folder: $($Folder.FullName)"
    Remove-Item -Path $Folder.FullName -Force -Recurse
}

Write-Output "Cleanup complete."

pause