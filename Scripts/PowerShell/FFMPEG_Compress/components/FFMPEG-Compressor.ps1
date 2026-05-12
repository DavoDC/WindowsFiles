param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile
)

$ScriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$FfmpegDir    = Join-Path $ScriptDir "ffmpeg"
$LogDir       = Join-Path $ScriptDir "logs"
$SessionStart = Get-Date

# Validate input before anything else
if (-not (Test-Path $InputFile)) {
    Write-Host "ERROR: File not found: $InputFile"
    exit 1
}

$inputDir  = Split-Path -Parent $InputFile
$inputBase = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)

Write-Host ""
Write-Host "=== FFMPEG Compressor ==="
Write-Host "Input: $InputFile"

# Calculate input size for display in menu
$inputSizeMB = [math]::Round((Get-Item $InputFile).Length / 1MB, 2)
$quarterSizeMB = [math]::Round($inputSizeMB * 0.25, 2)
$halfSizeMB = [math]::Round($inputSizeMB * 0.5, 2)

Write-Host "Input size: ${inputSizeMB} MB"
Write-Host ""

# ── Target size selection ─────────────────────────────────────────────────────
Write-Host "  Target size:"
Write-Host "    [1] 4 MB"
Write-Host "    [2] 6 MB"
Write-Host "    [3] 8 MB"
Write-Host "    [4] Quarter size of original (${quarterSizeMB} MB)"
Write-Host "    [5] Half size of original (${halfSizeMB} MB)"
Write-Host "    [6] Custom (enter MB value)"
Write-Host ""
$choice = Read-Host "  Choose (1-6)"

$TargetSizeMB = switch ($choice.Trim()) {
    "1" { 4 }
    "2" { 6 }
    "3" { 8 }
    "4" { $quarterSizeMB }
    "5" { $halfSizeMB }
    "6" {
        $customInput = Read-Host "  Enter target size in MB"
        if ([double]::TryParse($customInput, [ref]$customMB) -and $customMB -gt 0) {
            $customMB
        } else {
            Write-Host "  Invalid input - defaulting to 4 MB."
            4
        }
    }
    default {
        Write-Host "  Invalid choice - defaulting to 4 MB."
        4
    }
}
Write-Host ""

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$LogFile = Join-Path $LogDir "${inputBase}_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

Start-Transcript -Path $LogFile -NoClobber | Out-Null

Write-Host "=== FFMPEG Compressor ==="
Write-Host "Started : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Input   : $InputFile"
Write-Host "Target  : $TargetSizeMB MB"
Write-Host ""

# ── Step 1: Locate FFmpeg ─────────────────────────────────────────────────────
Write-Host "[1/4] Locating FFmpeg..."

function Find-InDir {
    param([string]$Dir, [string]$Name)
    $result = Get-ChildItem -Path $Dir -Filter $Name -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($result) { return $result.FullName }
    return $null
}

$ffmpegExe  = $null
$ffprobeExe = $null

# Check local install first
if (Test-Path $FfmpegDir) {
    $ffmpegExe  = Find-InDir $FfmpegDir "ffmpeg.exe"
    $ffprobeExe = Find-InDir $FfmpegDir "ffprobe.exe"
}

# Check system PATH
if (-not $ffmpegExe) {
    $sysFF = Get-Command "ffmpeg"  -ErrorAction SilentlyContinue
    $sysFP = Get-Command "ffprobe" -ErrorAction SilentlyContinue
    if ($sysFF) {
        $ffmpegExe  = $sysFF.Source
        $ffprobeExe = if ($sysFP) { $sysFP.Source } else { $null }
        Write-Host "  Using system FFmpeg: $ffmpegExe"
    }
}

# Download if still not found
if (-not $ffmpegExe) {
    Write-Host "  FFmpeg not found - downloading..."
    if (-not (Test-Path $FfmpegDir)) { New-Item -ItemType Directory -Path $FfmpegDir | Out-Null }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Prefer 7-Zip (32 MB archive vs 80 MB zip)
    $7zExe = $null
    foreach ($candidate in @("7z", "7za", "$env:ProgramFiles\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe")) {
        if ($candidate -match '\\') {
            if (Test-Path $candidate -ErrorAction SilentlyContinue) { $7zExe = $candidate; break }
        } else {
            if (Get-Command $candidate -ErrorAction SilentlyContinue) { $7zExe = $candidate; break }
        }
    }

    if ($7zExe) {
        $archive = Join-Path $FfmpegDir "ffmpeg-dl.7z"
        Write-Host "  Downloading 7z archive (~32 MB)..."
        Invoke-WebRequest -Uri "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.7z" -OutFile $archive -UseBasicParsing
        Write-Host "  Extracting..."
        & $7zExe x $archive "-o$FfmpegDir" -y | Out-Null
        Write-Host "  Archive kept at: $archive"
    } else {
        $archive = Join-Path $FfmpegDir "ffmpeg-dl.zip"
        Write-Host "  7-Zip not found - downloading zip version (~80 MB). Install 7-Zip to use the smaller archive next time."
        Invoke-WebRequest -Uri "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" -OutFile $archive -UseBasicParsing
        Write-Host "  Extracting..."
        Expand-Archive -Path $archive -DestinationPath $FfmpegDir -Force
        Write-Host "  Archive kept at: $archive"
    }

    $ffmpegExe  = Find-InDir $FfmpegDir "ffmpeg.exe"
    $ffprobeExe = Find-InDir $FfmpegDir "ffprobe.exe"

    if (-not $ffmpegExe) {
        Write-Host "ERROR: ffmpeg.exe not found after download. Check $FfmpegDir"
        Stop-Transcript | Out-Null
        exit 1
    }
    Write-Host "  Installed: $ffmpegExe"
}

# Derive ffprobe from ffmpeg path if still null
if (-not $ffprobeExe) {
    $candidate = $ffmpegExe -replace "ffmpeg\.exe$", "ffprobe.exe"
    if (Test-Path $candidate) { $ffprobeExe = $candidate }
}
if (-not $ffprobeExe) {
    Write-Host "ERROR: ffprobe.exe not found alongside ffmpeg."
    Stop-Transcript | Out-Null
    exit 1
}

Write-Host "  ffmpeg : $ffmpegExe"
Write-Host "  ffprobe: $ffprobeExe"

# ── Step 2: Analyse input ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/4] Analysing input..."
$t2Start = Get-Date

$rawOutput = & $ffprobeExe -v error -show_entries format=duration `
    -of default=noprint_wrappers=1:nokey=1 "$InputFile" 2>&1
$rawDuration = ($rawOutput | Out-String).Trim()

[double]$duration = 0.0
if (-not [double]::TryParse($rawDuration, [ref]$duration) -or $duration -le 0) {
    Write-Host "ERROR: Cannot read video duration. ffprobe output: $rawDuration"
    Stop-Transcript | Out-Null
    exit 1
}

$durationFmt = [TimeSpan]::FromSeconds($duration).ToString("hh\:mm\:ss")

Write-Host "  Duration  : $durationFmt ($([math]::Round($duration,1))s)"
Write-Host "  Input size: ${inputSizeMB} MB"

# Adaptive audio bitrate - give more budget to video for longer clips
if ($duration -gt 600) {
    $audioBitrateKbps = 48
} elseif ($duration -gt 300) {
    $audioBitrateKbps = 64
} else {
    $audioBitrateKbps = 96
}

# 2% headroom for container overhead
$targetBytes     = $TargetSizeMB * 1024 * 1024 * 0.98
$totalBitrateBps = ($targetBytes * 8) / $duration
$videoBitrateBps = $totalBitrateBps - ($audioBitrateKbps * 1000)

if ($videoBitrateBps -lt 5000) {
    Write-Host "  WARNING: Video is very long - quality will be extremely low at ${TargetSizeMB} MB."
    $videoBitrateBps = 5000
}
$videoBitrateK = [int]($videoBitrateBps / 1000)

Write-Host "  Video bitrate: ${videoBitrateK} kbps"
Write-Host "  Audio bitrate: ${audioBitrateKbps} kbps"
Write-Host "  Analysis time: $([int]((Get-Date) - $t2Start).TotalSeconds)s"

# ── Step 3: Two-pass encode ───────────────────────────────────────────────────
$outputFile = Join-Path $inputDir "${inputBase}_${TargetSizeMB}mb.mp4"
$passlog    = Join-Path $env:TEMP "ffmpeg-pass-$PID"

Write-Host ""
Write-Host "[3/4] Two-pass encoding..."

# Pass 1 - analysis only, no audio written
# -nostdin prevents ffmpeg from reading stdin (causes hang when called from PowerShell)
Write-Host "  Pass 1/2 (analysis pass)..."
$t3aStart = Get-Date
& $ffmpegExe -nostdin -y -i "$InputFile" `
    -c:v libx264 -preset slow -profile:v high `
    -b:v "${videoBitrateK}k" `
    -pass 1 -passlogfile "$passlog" `
    -an -f null NUL

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Pass 1 failed (exit code $LASTEXITCODE)"
    Remove-Item "${passlog}*" -ErrorAction SilentlyContinue
    Stop-Transcript | Out-Null
    exit 1
}
Write-Host "  Pass 1 complete - $([int]((Get-Date) - $t3aStart).TotalSeconds)s"

# Pass 2 - full encode with audio
Write-Host "  Pass 2/2 (encode pass)..."
$t3bStart = Get-Date
& $ffmpegExe -nostdin -y -i "$InputFile" `
    -c:v libx264 -preset slow -profile:v high `
    -b:v "${videoBitrateK}k" `
    -pass 2 -passlogfile "$passlog" `
    -c:a aac -b:a "${audioBitrateKbps}k" `
    -af aresample=async=1 `
    -movflags +faststart `
    "$outputFile"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Pass 2 failed (exit code $LASTEXITCODE)"
    Remove-Item "${passlog}*" -ErrorAction SilentlyContinue
    Stop-Transcript | Out-Null
    exit 1
}
Write-Host "  Pass 2 complete - $([int]((Get-Date) - $t3bStart).TotalSeconds)s"

Remove-Item "${passlog}*" -ErrorAction SilentlyContinue

# ── Step 4: Results ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[4/4] Results"

if (Test-Path $outputFile) {
    $outBytes = (Get-Item $outputFile).Length
    $inBytes  = (Get-Item $InputFile).Length
    $outMB    = [math]::Round($outBytes / 1MB, 2)
    $ratio    = [math]::Round(($outBytes / $inBytes) * 100, 1)

    Write-Host "  Output : $outputFile"
    Write-Host "  Size   : ${outMB} MB  (limit: ${TargetSizeMB} MB)"
    Write-Host "  Ratio  : ${ratio}% of original size"

    if ($outBytes -gt $TargetSizeMB * 1024 * 1024) {
        Write-Host "  NOTE   : Slightly over limit (container overhead). Reduce headroom from 0.98 to 0.96 in the script if needed."
    } else {
        Write-Host "  Status : OK - within target."
    }
} else {
    Write-Host "  ERROR: Output file was not created."
}

$totalSec = [int]((Get-Date) - $SessionStart).TotalSeconds
$elapsed  = "{0}m {1}s" -f [int]($totalSec / 60), ($totalSec % 60)

Write-Host ""
Write-Host "=== Complete ==="
Write-Host "Finished : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Elapsed  : $elapsed"
Write-Host "Log      : $LogFile"
Write-Host ""

Stop-Transcript | Out-Null
