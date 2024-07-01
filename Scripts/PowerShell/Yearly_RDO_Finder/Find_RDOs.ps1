# Function to check if a given date is an RDO
function Test-DateRDO($date) {
    $daysDifference = ($date - (Get-Date -Date "2023-10-03")).Days
    $isTuesday = $date.DayOfWeek -eq [System.DayOfWeek]::Tuesday
    return ($daysDifference % 14 -eq 0) -and $isTuesday
}

# Get the current year
$currentYear = (Get-Date).Year

# Iterate over all days of the current year
$startDate = Get-Date -Year $currentYear -Month 1 -Day 1
$endDate = Get-Date -Year $currentYear -Month 12 -Day 31

# Track the current month
$currentMonth = 0

Write-Output ""
Write-Output ""

for ($date = $startDate; $date -le $endDate; $date = $date.AddDays(1)) {
    if ($date.Month -ne $currentMonth) {
        # Print the month heading
        Write-Output ""
        Write-Output $date.ToString("MMMM yyyy")
        Write-Output "-------------------"
        $currentMonth = $date.Month
    }
    if (Test-DateRDO $date) {
        Write-Output $date.ToString("yyyy-MM-dd")
    }
}

Write-Output ""
Write-Output ""
