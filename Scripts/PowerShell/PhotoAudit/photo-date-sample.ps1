# photo-date-sample.ps1
# Samples 3 photos from each event folder and prints all date-related EXIF/shell fields
# Purpose: identify which field = "date taken" before building the full collector

$eventRoot = "C:\Users\David\GoogleDrive\Photos\Camera Photos\Events"
$shell = New-Object -ComObject Shell.Application

$folders = Get-ChildItem $eventRoot -Directory | Select-Object -First 5

foreach ($folder in $folders) {
    $files = Get-ChildItem $folder.FullName -Include *.jpg,*.jpeg,*.png,*.mp4,*.mov -Recurse -ErrorAction SilentlyContinue | Select-Object -First 3
    foreach ($file in $files) {
        $shellFolder = $shell.Namespace($file.DirectoryName)
        $shellFile   = $shellFolder.ParseName($file.Name)

        Write-Output "=== $($file.FullName) ==="
        Write-Output "  FS CreationTime:  $($file.CreationTime)"
        Write-Output "  FS LastWriteTime: $($file.LastWriteTime)"

        for ($i = 0; $i -lt 320; $i++) {
            $name = $shellFolder.GetDetailsOf($null, $i)
            $val  = $shellFolder.GetDetailsOf($shellFile, $i)
            if ($name -match "date|time|creat|taken|modif" -and $val -ne "") {
                Write-Output "  [$i] $name = $val"
            }
        }
        Write-Output ""
    }
}
