#######################################################################################
#                                File List Generator                                  #
#######################################################################################
# Description: Script to generate file names for a folder with movies ignoring other  #
#              common file types from the file listing                                #
#                                                                                     #
# Run Command: filelist.ps1 [path] [(boolean)recursive] [(boolean)ignoreSample]       #
# Parameters:                                                                         #
#   path = Folder for which file list is to be generated (Default: Current Folder)    #
#   recursize = Search inner folders? (Default: false)                                #
#   ignoreSample = Ignores files that contain the words "sample" and proof            #
#                  case insensitively (Default: false)                                #
# Example: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -command         #
           "& 'C:\Users\Karun\My Scripts\filelist.ps1'" "." "true" "true"             #
#                                                                                     #
# Version: 1.03                                                                       #
# Creator: Karun AB (JAnderton)                                                       #
# Link: https://github.com/JAnderton/Scriptlets                                       #
#######################################################################################

# Function to check if extention is one of the rejected ones
# or if the "file" entry is a directory
# or if the "file" is a sample video
function fileCheck([string]$extention, [string]$attributes, [string]$filename, [string]$nameCheck) {
    # list of rejected extentions
    $exts = ".srt",".sub",".idx",".txt",".lnk",".sfv",".nfo",".jpg",".jpeg",".png",".bmp",".log"
    
    if ($extention -eq ".!ut") {
        $extention = $filename.SubString($filename.LastIndexOf("."));
    }
    
    $retVal = $exts -notcontains $extention -and $attributes -ne "Directory";
    
    if ($nameCheck -eq "true") {
        $retVal = $retVal -and (-not $filename.ToLower().Contains("sample")) -and (-not $filename.ToLower().Contains("proof"));
    }
    
    return $retVal;
}

# Did the user request for help?
if ($args[0] -eq "--help" -or $args[0] -eq "/?") {
    Write-Host("filelist.ps1 [path] [(boolean)recursive] [(boolean)ignoreSample]")
    exit("Help given");
}

$path = $args[0];       # Path to files
# Checking if path is passed
if ($args[0] -eq $null) {
    Write-Host("No argument passed")
    $path = ".";
}

$nameCheck = $args[2]       # Saving parameter stating if name is to be checked for samples

# Checking path validity
if ((Test-Path -path $path) -ne $true) {
    Write-Host("Path invalid")
    exit("Error: path");
}

$output = ""                # Clearing past lists for session safety
$count = 0                  # Clearing past counts for session safety

# Getting file list once (efficiency :))
if ($args[1] -eq $null -or $args[1] -eq "false") {
    $fileList = get-childitem $path | where {fileCheck $_.Extension $_.Attributes $_.BaseName $nameCheck}
} elseif ($args[1] -eq "true") {
    $fileList = get-childitem $path -recurse | where {fileCheck $_.Extension $_.Attributes $_.BaseName $nameCheck}
} else {
    Write-Host("Invalid recursive choice")
    exit("Error: recurse");
}

# Generating human readable file list (with file names)
$fileList | Select-Object Name | ForEach-Object {$output += $_.Name + "`r`n"}
$output += "`r`n"

# Generating copy pastable file list (with base names)
$fileList | Select-Object BaseName | ForEach-Object {$output += $_.BaseName + ", "}
$output = $output.Remove($output.length-2,1)

# Calculating total size
$fileSize = [math]::Round(($fileList | Measure-Object -property length -sum).sum / 1GB, 2)

# Getting object count
$output += "[" + $fileList.count + " files; " + $fileSize + "GB]"

# Writing data to file
$output | out-File $path\list.txt