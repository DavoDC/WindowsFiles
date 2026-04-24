# photo-collector.ps1
# Collects photo metadata (Date Taken, dates, sizes) from a folder tree
# Run from USB - logs saved to .\logs\ relative to this script
# Usage: .\photo-collector.ps1 -RootPath "D:\Family Photos"
# Output: two CSVs - per-file detail + per-folder summary

param(
    [Parameter(Mandatory=$true)]
    [string]$RootPath
)

$startTime = Get-Date
$timestamp = $startTime.ToString("yyyyMMdd-HHmmss")
$scriptDir = $PSScriptRoot
$logDir    = Join-Path $scriptDir "logs"
$detailCsv = Join-Path $logDir "photo-data-$timestamp.csv"
$summaryCsv = Join-Path $logDir "folder-summary-$timestamp.csv"
$logFile   = Join-Path $logDir "photo-collector-$timestamp.log"

if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

function Log($msg) {
    $line = "$(Get-Date -Format 'HH:mm:ss') $msg"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

Log "photo-collector.ps1 starting"
Log "Root path: $RootPath"
Log "Output dir: $logDir"

# Load System.Drawing for fast EXIF reading
Add-Type -AssemblyName System.Drawing

function Get-ExifDateTaken($filePath) {
    try {
        $img = [System.Drawing.Image]::FromFile($filePath)
        try {
            # Property ID 36867 = DateTimeOriginal (EXIF shutter date)
            $prop = $img.GetPropertyItem(36867)
            $raw  = [System.Text.Encoding]::ASCII.GetString($prop.Value).TrimEnd([char]0)
            # Format: "YYYY:MM:DD HH:MM:SS"
            if ($raw -match "^(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})$") {
                return [datetime]"$($Matches[1])-$($Matches[2])-$($Matches[3]) $($Matches[4]):$($Matches[5]):$($Matches[6])"
            }
        } catch { }
        finally { $img.Dispose() }
    } catch { }
    return $null
}

Log "Scanning files..."
$extensions = @("*.jpg","*.jpeg","*.png","*.mp4","*.mov","*.avi","*.heic","*.gif","*.bmp","*.tif","*.tiff")
$files = Get-ChildItem -Path $RootPath -Recurse -Include $extensions -ErrorAction SilentlyContinue
Log "Found $($files.Count) files"

$rows   = [System.Collections.Generic.List[PSCustomObject]]::new()
$processed = 0

foreach ($file in $files) {
    $processed++
    if ($processed % 500 -eq 0) { Log "  ... $processed / $($files.Count)" }

    $dateTaken = $null
    $extension = $file.Extension.ToLower()
    if ($extension -in @(".jpg",".jpeg",".tif",".tiff")) {
        $dateTaken = Get-ExifDateTaken $file.FullName
    }

    $rows.Add([PSCustomObject]@{
        Folder       = $file.DirectoryName
        Filename     = $file.Name
        Extension    = $extension
        DateTaken    = if ($dateTaken) { $dateTaken.ToString("yyyy-MM-dd HH:mm:ss") } else { "" }
        DateModified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        DateCreated  = $file.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")
        SizeKB       = [math]::Round($file.Length / 1KB, 1)
        FullPath     = $file.FullName
    })
}

Log "Writing detail CSV..."
$rows | Export-Csv -Path $detailCsv -NoTypeInformation -Encoding UTF8

# Folder summary
Log "Building folder summary..."
$summary = $rows | Group-Object Folder | ForEach-Object {
    $group = $_.Group
    $takenDates = $group | Where-Object { $_.DateTaken -ne "" } | ForEach-Object { [datetime]$_.DateTaken }
    $modDates   = $group | ForEach-Object { [datetime]$_.DateModified }
    $bestDates  = if ($takenDates.Count -gt 0) { $takenDates } else { $modDates }

    [PSCustomObject]@{
        Folder        = $_.Name
        FileCount     = $group.Count
        TotalSizeMB   = [math]::Round(($group | Measure-Object SizeKB -Sum).Sum / 1KB, 2)
        WithDateTaken = ($group | Where-Object { $_.DateTaken -ne "" }).Count
        EarliestDate  = ($bestDates | Sort-Object | Select-Object -First 1).ToString("yyyy-MM-dd")
        LatestDate    = ($bestDates | Sort-Object -Descending | Select-Object -First 1).ToString("yyyy-MM-dd")
    }
}
$summary | Sort-Object EarliestDate | Export-Csv -Path $summaryCsv -NoTypeInformation -Encoding UTF8

$endTime  = Get-Date
$duration = $endTime - $startTime
$totalGB  = [math]::Round(($rows | Measure-Object SizeKB -Sum).Sum / 1MB, 2)

Log ""
Log "Done."
Log "  Files processed : $($rows.Count)"
Log "  Total size      : $totalGB GB"
Log "  Files with EXIF : $(($rows | Where-Object { $_.DateTaken -ne '' }).Count)"
Log "  Duration        : $([math]::Round($duration.TotalMinutes, 1)) min"
Log "  Detail CSV      : $detailCsv"
Log "  Folder summary  : $summaryCsv"
