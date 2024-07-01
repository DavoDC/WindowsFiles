
######### Standup Speech Generator #########

## Constants
$templateFileName = "Template Standup Speech.txt"
$outputFolder = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
$overwriteFiles = $true # USE WITH CAUTION

### Helper Functions ###

# Handle existing files/folders
function Test-Existence {
    param(
        [string]$path
    )

    # If file or folder exists
    if (Test-Path $path) {

        if ($overwriteFiles) {

            # If overwrite on, remove it - it will be recreated.
            Remove-Item -Path $path -Force -Recurse:$false
        } else {

            # Else if overwrite off, stop to prevent overwriting.
            $leafName = Split-Path -Path $path -Leaf
            $existenceMessage = if (Test-Path -PathType Container $path) { "Folder" } else { "File" }
            Write-Host "`n$existenceMessage already exists: '$leafName'"            
            Write-Host "Script stopped."
            Stop-For-User
            Exit
        }
    }
}

# Return true if the given date is an RDO
function Test-DateRDO($date) {
    $daysDifference = ($date - (Get-Date -Date "2023-10-03")).Days
    $isTuesday = $date.DayOfWeek -eq [System.DayOfWeek]::Tuesday
    return ($daysDifference % 14 -eq 0) -and $isTuesday
}

# Generates a standup speech file for a given date, template and month folder
function New-Speech($date, $templateContent, $monthFolderPath) {

    # If the date is a weekend, stop
    if ($date.DayOfWeek -eq "Saturday" -or $date.DayOfWeek -eq "Sunday") {
        return
    }
    
    # If the date is an RDO, notify and stop
    if (Test-DateRDO($date)) {
        Write-Host "Skipped RDO: $($date.ToString('dd-MM-yyyy'))"
        return
    }

    # Determine yesterday day name
    $yesterday = $date.AddDays(-1)
    $yesterdayDayName = $yesterday.DayOfWeek.ToString()

    if ($date.DayOfWeek -eq "Monday") {
        $yesterdayDayName = "Friday"
    }

    if ($date.DayOfWeek -eq "Wednesday" -and (Test-DateRDO $yesterday)) {
        $yesterdayDayName = "Monday"
    }
    
    # Replace placeholders in the template with actual values
    $speechContent = $templateContent -replace "<DAY>", $date.DayOfWeek.ToString().ToUpper()
    $speechContent = $speechContent -replace "<DD>", $date.Day.ToString("00")
    $speechContent = $speechContent -replace "<MM>", $date.Month.ToString("00")
    $speechContent = $speechContent -replace "<YYYY>", $date.Year.ToString("00")
    $speechContent = $speechContent -replace "<YESTERDAY>", $yesterdayDayName.ToUpper()

    # Get speech file name and path
    $speechFileNameBase = "{0:yyyy-MM-dd} - {0:dddd} Standup Speech" -f $date
    $speechFilePath = Join-Path -Path $monthFolderPath -ChildPath ($speechFileNameBase + ".txt")

    # Check if the speech file already exists
    Test-Existence -path $speechFilePath

    # Create the speech file
    $speechContent | Set-Content -Path $speechFilePath
}

function New-Speeches($targetMonth, $templateContent, $monthFolderPath) {

    # For each day in the target month
    for ($day = 1; $day -le $targetMonth.Day; $day++) {    

        # Get the date
        $date = Get-Date -Year $targetMonth.Year -Month $targetMonth.Month -Day $day

        # Generate the standup speech for the current date
        try {
            New-Speech $date $templateContent $monthFolderPath
        } catch {
            Write-Host "`nError occurred!"
            Write-Host "$_"
            exit 1
        }
    }
}

# Pauses so the user can read output
function Stop-For-User {
    Write-Host "`n(Script Finished)"
    $null = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

function Get-TargetMonth($choice)
{
    # Get the current date
    $today = Get-Date

    # Calculate the target month based on the user's choice
    if ($choice -eq '1') {
        $target = $today
    } elseif ($choice -eq '2') {
        $target = $today.AddMonths(1)
    }    

    # Set the day to the last day of the month
    $lastDayOfMonth = (Get-Date -Year $target.Year -Month $target.Month -Day 1).AddMonths(1).AddDays(-1)

    return $lastDayOfMonth
}

### Actual Script Execution ###

# Start message
Write-Host "`n### Welcome to the Standup Speech Generator ###"
Write-Host "`n1) Current Month"
Write-Host "2) Next Month"
Write-Host "3) Cancel/Exit"
$choice = Read-Host "`nChoice"

# Check choice validity
if ($choice -notin '1', '2', '3') {
    Write-Host "`nInvalid option. Exiting...`n"
    exit
}

# Exit option
if ($choice -eq '3') {
    exit 
}

# Get template content
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$templateFilePath = Join-Path -Path $scriptDirectory -ChildPath $templateFileName
if (-not (Test-Path $templateFilePath)) {
    Write-Host "`nTemplate not found. Script stopped."       
    Stop-For-User
    Exit
}
$templateContent = Get-Content -Path $templateFilePath

# Get month and notify
$targetMonth = Get-TargetMonth $choice
$monthFolderName = "{0:MM} - {0:MMMM}" -f $targetMonth
Write-Host "Chosen Month: $monthFolderName"

# Create the month folder if it doesn't exist
$monthFolderPath = Join-Path -Path $outputFolder -ChildPath "$monthFolderName"
Test-Existence -path $monthFolderPath
New-Item -ItemType Directory -Path $monthFolderPath | Out-Null

# Generate speeches
New-Speeches $targetMonth $templateContent $monthFolderPath

# Finish message
Write-Host "`nSpeeches generated successfully in:"
Write-Host "$monthFolderPath"
Stop-For-User