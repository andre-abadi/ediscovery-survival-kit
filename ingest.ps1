# Prompt the user for the source directory path
$sourceDirectory = Read-Host "Enter the path to the source directory"

# Prompt the user for the destination directory path
$destinationDirectory = Read-Host "Enter the path to the destination directory"

# Prompt the user for the starting bates number
do {
    $batesNumber = Read-Host "Enter the starting bates number (in the format of 'ABC.0001.0001.0001')"
} until ($batesNumber -match '^[a-zA-Z]+\.\d{4}\.\d{4}\.\d{4}$')

# Get the parent directory of the destination directory
$parentDirectory = Split-Path $destinationDirectory -Parent

# Split the starting bates number into its constituent parts
$prefix, $firstNumber, $secondNumber, $thirdNumber = $batesNumber -split '\.'

# Initialize the counter for the last four digits of the bates number
$lastFourDigits = [int]$thirdNumber

# Recursively loop through each file in the source directory
Get-ChildItem -Path $sourceDirectory -Recurse -File | ForEach-Object {

    # Get the file extension of the original file
    $extension = $_.Extension

    # Create a new filename based on the bates number
    $newFilename = "$prefix.$firstNumber.$secondNumber.{0:D4}$extension" -f $lastFourDigits

    # Copy the file to the destination directory using the new filename
    $newFilePath = Join-Path $destinationDirectory $newFilename
    Copy-Item -Path $_.FullName -Destination $newFilePath

    # Output a CSV row with the bates number, original filename, and original path
    [PSCustomObject]@{
        BatesNumber = "$prefix.$firstNumber.$secondNumber.{0:D4}" -f $lastFourDigits
        OriginalFilename = $_.Name
        OriginalPath = $_.FullName
    } | Export-Csv -Path "$parentDirectory\output.csv" -Append -NoTypeInformation

    # Increment the counter for the last four digits of the bates number
    $lastFourDigits++
}
