# photo-collector.ps1
# Collects photo metadata (all date fields + location hints from folder names) from entire directory tree
# Accepts root path as argument, scans recursively, logs to .\logs\
# Usage: .\photo-collector.ps1 -RootPath "H:\PARENTS_USER_FOLDER_BACKUP"
# Output: two CSVs - per-file detail (all metadata dates) + per-folder summary with location hints

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

if (-not (Test-Path $RootPath)) {
    Log "ERROR: Root path does not exist: $RootPath"
    exit 1
}

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

function Extract-LocationHint($folderPath, $fileName) {
    # Extract location/country/region hints from folder and file names
    $hints = @()
    $pathParts = $folderPath -split '\\'
    $fileBase = [System.IO.Path]::GetFileNameWithoutExtension($fileName)

    foreach ($part in $pathParts) {
        # Look for country codes, state abbreviations, or location keywords
        if ($part -match "(?i)(australia|aus|wa|perth|sydney|victoria|queensland|nsw|act|nt|sa|tasmania|tas|melbourne|brisbane|adelaide|hobart|canberra|darwin|gold coast|blue mountains)") {
            $hints += $Matches[0]
        }
        elseif ($part -match "(?i)(new zealand|nz|auckland|christchurch|wellington|fiji|samoa|tonga|vanuatu|bali|indonesia|singapore|malaysia|thailand|phuket|bangkok|hong kong)") {
            $hints += $Matches[0]
        }
        elseif ($part -match "(?i)(europe|europe|austria|hungary|romania|greece|turkey|switzerland|italy|france|london|england|ireland|scotland|spain|portugal|germany)") {
            $hints += $Matches[0]
        }
        elseif ($part -match "(?i)(usa|america|hawaii|california|new york|chicago|florida|las vegas|nevada|utah|colorado|washington|oregon|arizona|chile|argentina|mexico|canada)") {
            $hints += $Matches[0]
        }
        elseif ($part -match "(?i)(africa|mauritius|egypt|south africa|cape town|madagascar|reunion|maldives|indian ocean)") {
            $hints += $Matches[0]
        }
        elseif ($part -match "(?i)(antarctic|antarctica|cruise|ship|boat)") {
            $hints += $Matches[0]
        }
        elseif ($part -match "(?i)(2\d{3}|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|holiday|vacation|trip|travel|event|summer|winter)") {
            $hints += $Matches[0]
        }
    }

    # Also check filename for hints
    if ($fileBase -match "(?i)(australia|aus|wa|sydney|melbourne|brisbane|perth|adelaide|hobart|canberra|darwin|gold coast|blue mountains|new zealand|nz|fiji|samoa|bali|singapore|malaysia|europe|austria|hungary|romania|greece|turkey|switzerland|italy|london|england|spain|portugal|usa|hawaii|california|chile|argentina|mauritius|maldives|cruise|trip)") {
        $hints += $Matches[0]
    }

    return ($hints | Select-Object -Unique) -join "; "
}

Log "Scanning files recursively..."
$extensions = @("*.jpg","*.jpeg","*.png","*.mp4","*.mov","*.avi","*.webm","*.heic","*.gif","*.bmp","*.tif","*.tiff","*.raw","*.arw","*.dng")
$files = Get-ChildItem -Path $RootPath -Recurse -Include $extensions -ErrorAction SilentlyContinue
Log "Found $($files.Count) image/video files"

$rows   = [System.Collections.Generic.List[PSCustomObject]]::new()
$processed = 0

foreach ($file in $files) {
    $processed++
    if ($processed % 500 -eq 0) { Log "  ... $processed / $($files.Count) processed" }

    $dateTaken = $null
    $extension = $file.Extension.ToLower()

    # Extract EXIF DateTaken for image files
    if ($extension -in @(".jpg",".jpeg",".tif",".tiff",".raw",".arw",".dng")) {
        $dateTaken = Get-ExifDateTaken $file.FullName
    }

    # Extract location hints from path and filename
    $locationHints = Extract-LocationHint $file.DirectoryName $file.Name

    # Use best available date
    $bestDate = if ($dateTaken) { $dateTaken } else { $file.LastWriteTime }

    $rows.Add([PSCustomObject]@{
        Folder       = $file.DirectoryName
        Filename     = $file.Name
        Extension    = $extension
        DateTaken    = if ($dateTaken) { $dateTaken.ToString("yyyy-MM-dd HH:mm:ss") } else { "" }
        DateModified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        DateCreated  = $file.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")
        BestDate     = $bestDate.ToString("yyyy-MM-dd")
        BestDateFull = $bestDate.ToString("yyyy-MM-dd HH:mm:ss")
        LocationHints = $locationHints
        SizeKB       = [math]::Round($file.Length / 1KB, 1)
        FullPath     = $file.FullName
    })
}

Log "Writing detail CSV..."
$rows | Export-Csv -Path $detailCsv -NoTypeInformation -Encoding UTF8

# Folder summary with location hints
Log "Building folder summary..."
$summary = $rows | Group-Object Folder | ForEach-Object {
    $group = $_.Group
    $takenDates = $group | Where-Object { $_.DateTaken -ne "" } | ForEach-Object { [datetime]$_.DateTaken }
    $modDates   = $group | ForEach-Object { [datetime]$_.DateModified }
    $bestDates  = if ($takenDates.Count -gt 0) { $takenDates } else { $modDates }

    # Collect all unique location hints from this folder
    $allHints = $group | Where-Object { $_.LocationHints -ne "" } | ForEach-Object { $_.LocationHints } | Sort-Object -Unique
    $folderHints = $allHints -join "; "

    [PSCustomObject]@{
        Folder        = $_.Name
        FileCount     = $group.Count
        TotalSizeMB   = [math]::Round(($group | Measure-Object SizeKB -Sum).Sum / 1KB, 2)
        WithDateTaken = ($group | Where-Object { $_.DateTaken -ne "" }).Count
        EarliestDate  = ($bestDates | Sort-Object | Select-Object -First 1).ToString("yyyy-MM-dd")
        LatestDate    = ($bestDates | Sort-Object -Descending | Select-Object -First 1).ToString("yyyy-MM-dd")
        LocationHints = $folderHints
    }
}
$summary | Sort-Object EarliestDate | Export-Csv -Path $summaryCsv -NoTypeInformation -Encoding UTF8

$endTime  = Get-Date
$duration = $endTime - $startTime
$totalGB  = [math]::Round(($rows | Measure-Object SizeKB -Sum).Sum / 1MB, 2)

Log ""
Log "========================================"
Log "SUMMARY"
Log "========================================"
Log "Files processed : $($rows.Count)"
Log "Total size      : $totalGB GB"
Log "Files with EXIF : $(($rows | Where-Object { $_.DateTaken -ne '' }).Count)"
Log "Duration        : $([math]::Round($duration.TotalSeconds)) seconds"
Log ""
Log "Output files:"
Log "  Detail CSV     : $detailCsv"
Log "  Folder summary : $summaryCsv"
Log "========================================"
