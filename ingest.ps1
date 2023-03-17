# Prompt the user for the source directory path, defaulting to "_sample_data" if no input is given
$sourceDirectory = Read-Host "Enter the path to the source directory (default: `_sample_data`)"
if (-not $sourceDirectory) {
    $parentDirectory = Split-Path $MyInvocation.MyCommand.Path -Parent
    $sourceDirectory = Join-Path $parentDirectory "_sample_data"
}

# Define the path to the destination directory (inside an Evidence folder one directory above where the script is being run)
$parentDirectory = Split-Path $MyInvocation.MyCommand.Path -Parent
$destinationDirectory = Join-Path $parentDirectory "Evidence"

# Prompt the user for the starting bates number
do {
    $batesNumber = Read-Host "Enter the starting bates number (in the format of 'ABC.0001.0001.0001')"
} until ($batesNumber -match '^[a-zA-Z]+\.\d{4}\.\d{4}\.\d{4}$')

# Get the parent directory of the destination directory
$parentDirectory = Split-Path $destinationDirectory -Parent

# Define a function to create subdirectories for a given bates number
function CreateSubdirectories($batesNumber) {
    # Split the bates number into its constituent parts
    $prefix, $firstNumber, $secondNumber, $thirdNumber = $batesNumber -split '\.'

    # Create the subdirectory paths
    $firstSubdirectory = Join-Path $destinationDirectory $prefix
    $secondSubdirectory = Join-Path $firstSubdirectory $firstNumber
    $thirdSubdirectory = Join-Path $secondSubdirectory $secondNumber

    # Create the subdirectories if they don't already exist
    if (-not (Test-Path $firstSubdirectory)) {
        New-Item -Path $firstSubdirectory -ItemType Directory | Out-Null
    }
    if (-not (Test-Path $secondSubdirectory)) {
        New-Item -Path $secondSubdirectory -ItemType Directory | Out-Null
    }
    if (-not (Test-Path $thirdSubdirectory)) {
        New-Item -Path $thirdSubdirectory -ItemType Directory | Out-Null
    }

    # Return the path to the third subdirectory
    return $thirdSubdirectory
}

# Split the starting bates number into its constituent parts
$prefix, $firstNumber, $secondNumber, $thirdNumber = $batesNumber -split '\.'

# Initialize the counter for the last four digits of the bates number
$lastFourDigits = [int]$thirdNumber

# Recursively loop through each file in the source directory
Get-ChildItem -Path $sourceDirectory -Recurse -File | ForEach-Object {

    # Get the file extension of the original file
    $extension = $_.Extension

    # Calculate the MD5 hash of the file
    $md5 = (Get-FileHash $_.FullName -Algorithm MD5).Hash

    # Create a new filename based on the bates number
    $newFilename = "$prefix.$firstNumber.$secondNumber.{0:D4}$extension" -f $lastFourDigits

    # Create subdirectories for the bates number and copy the file to the destination directory using the new filename
    $subdirectoryPath = CreateSubdirectories "$prefix.$firstNumber.$secondNumber"
    $newFilePath = Join-Path $subdirectoryPath $newFilename
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