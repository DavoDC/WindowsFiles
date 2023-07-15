
######### Standup Speech Generator #########

### Constants ###

# Set to true to overwrite files. USE WITH CAUTION. FOR TESTING ONLY
$overwriteFiles = $false
$overwriteFiles = $false


### Helper Functions ###

# Pauses so the user can read output
function PauseForUser {
    Write-Host "`nPress any key to exit..."
    $null = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

# Check if a file exists and handle accordingly
function CheckIfExistsAndHandle {
    param(
        [string]$path
    )

    # If file or folder exists
    if (Test-Path $path) {
        if ($overwriteFiles) {
            # If overwrite on, remove it - it will be recreated.
            # DISABLE FOR SAFETY
            # Remove-Item -Path $path -Force -Recurse:$false
        } else {
            # Else if overwrite off, stop to prevent overwriting.
            $leafName = Split-Path -Path $path -Leaf
            $existenceMessage = if (Test-Path -PathType Container $path) { "Folder" } else { "File" }
            Write-Host "`n$existenceMessage already exists: '$leafName'"            
            Write-Host "Script stopped."
            PauseForUser
            Exit
        }
    }
}

# Generates a standup speech file for a given date, template and month folder
function GenerateStandupSpeech($date, $templateContent, $monthFolderPath) {
    # Stop if the date is a weekend
    if ($date.DayOfWeek -eq "Saturday" -or $date.DayOfWeek -eq "Sunday") {
        return
    }
    
    # Get speech file name and path
    $speechFileName = "{0:yyyy-MM-dd} - {0:dddd} Standup Speech.txt" -f $date
    $speechFilePath = Join-Path -Path $monthFolderPath -ChildPath $speechFileName

    # Check if the speech file already exists
    CheckIfExistsAndHandle -path $speechFilePath

    # Determine the day name for yesterday based on the current day
    $yesterdayDayName = $date.AddDays(-1).DayOfWeek.ToString()
    if ($date.DayOfWeek -eq "Monday") {
        $yesterdayDayName = "Friday"
    }
    
    # Replace placeholders in the template with actual values
    $speechContent = $templateContent -replace "<DAY>", $date.DayOfWeek.ToString().ToUpper()
    $speechContent = $speechContent -replace "<DD>", $date.Day.ToString("00")
    $speechContent = $speechContent -replace "<MM>", $date.Month.ToString("00")
    $speechContent = $speechContent -replace "<YYYY>", $date.Year.ToString("00")
    $speechContent = $speechContent -replace "<YESTERDAY>", $yesterdayDayName.ToUpper()

    # Create the speech file
    $speechContent | Set-Content -Path $speechFilePath
}

### Actual Script Execution ###

# Prompt the user to select the month for generating speeches
Write-Host "`n### Welcome to the Standup Speech Generator ###"
$choice = Read-Host "`nType 'next' for next month or Press Enter for current month"

# Calculate the target month based on the user's choice
$today = Get-Date
$targetMonth = if ($choice.ToLower() -eq "next") { $today.AddMonths(1) } else { $today }

# Get the script directory
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Create the month folder if it doesn't exist
$monthFolderName = "{0:MM} - {0:MMMM}" -f $targetMonth
$monthFolderPath = Join-Path -Path $scriptDirectory -ChildPath "..\$monthFolderName"
CheckIfExistsAndHandle -path $monthFolderPath
New-Item -ItemType Directory -Path $monthFolderPath | Out-Null

# Get the template file content
$templateFilePath = Join-Path -Path $scriptDirectory -ChildPath "Template Standup Speech.txt"
$templateContent = Get-Content -Path $templateFilePath

# Loop through each day of the target month
for ($day = 1; $day -le $targetMonth.Day; $day++) {    
    $date = Get-Date -Year $targetMonth.Year -Month $targetMonth.Month -Day $day

    # Generate the standup speech for the current date
    try {
        GenerateStandupSpeech $date $templateContent $monthFolderPath
    } catch {
        Write-Host "`nError occurred!"
        Write-Host "$_"
        exit 1
    }
}

# Finish message
Write-Host "`nSpeeches generated successfully in: $monthFolderName"
PauseForUser