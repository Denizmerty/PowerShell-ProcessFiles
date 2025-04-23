#Requires -Version 5.1

Clear-Host

$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$windowsPrincipal = [System.Security.Principal.WindowsPrincipal]$currentUser

if (-not $windowsPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script requires Administrator privileges to run. Please right-click on the PowerShell executable and select 'Run as administrator' before running this script."
    Read-Host "Press Enter to exit..."
    exit 1
}

$CombineOutputFilename = "combined_text_files.txt"
$ListOutputFilename    = "file_list.txt"

$TextExtensions = @{
    '.txt' = $true; '.log' = $true; '.md' = $true; '.markdown' = $true; '.csv' = $true; '.tsv' = $true; '.json' = $true; '.yaml' = $true; '.yml' = $true; '.toml' = $true
    '.ini' = $true; '.cfg' = $true; '.conf' = $true; '.properties' = $true; '.env' = $true; '.inf' = $true; '.rtf' = $true; '.nfo' = $true; '.diz' = $true
    '.html' = $true; '.htm' = $true; '.xhtml' = $true; '.css' = $true; '.scss' = $true; '.less' = $true; '.js' = $true; '.jsx' = $true; '.ts' = $true; '.tsx' = $true
    '.php' = $true; '.asp' = $true; '.aspx' = $true; '.jsp' = $true; '.vue' = $true; '.svelte' = $true; '.jsonld' = $true; '.webmanifest' = $true
    '.xml' = $true; '.xaml' = $true; '.svg' = $true; '.kml' = $true; '.gpx' = $true; '.plist' = $true; '.storyboard' = $true; '.strings' = $true
    '.tex' = $true; '.bib' = $true; '.Rmd' = $true
    '.py' = $true; '.pyw' = $true; '.ipynb' = $true
    '.java' = $true; '.kt' = $true; '.kts' = $true; '.gradle' = $true
    '.c' = $true; '.cpp' = $true; '.h' = $true; '.hpp' = $true; '.cxx' = $true; '.hxx' = $true
    '.cs' = $true; '.vb' = $true; '.fs' = $true; '.fsx' = $true
    '.sh' = $true; '.bash' = $true; '.zsh' = $true; '.fish' = $true; '.csh' = $true; '.ksh' = $true
    '.bat' = $true; '.cmd' = $true; '.ps1' = $true; '.psm1' = $true
    '.rb' = $true; '.erb' = $true
    '.go' = $true
    '.rs' = $true
    '.swift' = $true
    '.m' = $true; '.mm' = $true
    '.pl' = $true; '.pm' = $true
    '.lua' = $true
    '.sql' = $true; '.ddl' = $true; '.dml' = $true
    '.r' = $true
    '.dart' = $true
    '.pas' = $true; '.pp' = $true; '.inc' = $true
    '.asm' = $true; '.s' = $true
    '.scala' = $true
    '.groovy' = $true
    '.clj' = $true; '.cljs' = $true; '.cljc' = $true; '.edn' = $true
    '.hs' = $true; '.lhs' = $true
    '.ex' = $true; '.exs' = $true
    '.csproj' = $true; '.vbproj' = $true; '.fsproj' = $true; '.vcxproj' = $true; '.sln' = $true; '.props' = $true; '.targets' = $true
    '.cmake' = $true
    '.pom' = $true
    '.glsl' = $true; '.frag' = $true; '.vert' = $true
    '.gd' = $true
    '.qml' = $true
    '.applescript' = $true
}

$SpecialTextFilenames = @(
    'Makefile', 'makefile', 'CMakeLists.txt', 'Dockerfile', 'Vagrantfile',
    'package.json', 'composer.json', 'requirements.txt', 'Pipfile', 'Gemfile'
) -as [System.Collections.Generic.HashSet[string]]

Function Get-ScriptDirectory {
    try {
        if ($PSScriptRoot) {
            return $PSScriptRoot
        } elseif ($MyInvocation -ne $null -and $MyInvocation.MyCommand -ne $null) {
            return Split-Path $MyInvocation.MyCommand.Path -Parent
        } else {
            return (Get-Location).Path
        }
    } catch {
        Write-Warning "Could not reliably determine script directory. Using current working directory '$((Get-Location).Path)' for output."
        return (Get-Location).Path
    }
}

Function Test-IsLikelyTextFile {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [System.IO.FileInfo]$FileObject
    )
    process {
        try {
            $filename = $FileObject.Name
            $extension = $FileObject.Extension

            if ($SpecialTextFilenames.Contains($filename)) {
                return $true
            }

            if ($TextExtensions.ContainsKey($extension.ToLowerInvariant())) {
                return $true
            }

            return $false
        } catch {
            Write-Warning "Could not determine type for '$($FileObject.FullName)': $($_.Exception.Message)"
            return $false
        }
    }
}

Function Get-ValidatedDirectory {
    param(
        [string]$PromptMessage = "Enter the full path to the directory to scan"
    )
    while ($true) {
        $rawTargetDir = Read-Host -Prompt $PromptMessage
        $rawTargetDir = $rawTargetDir.Trim().Trim('"')

        if ([string]::IsNullOrWhiteSpace($rawTargetDir)) {
            Write-Error "Directory path cannot be empty." -ErrorAction Continue
            continue
        }

        try {
            $absTargetDir = (Resolve-Path -LiteralPath $rawTargetDir -ErrorAction Stop).ProviderPath

            if (-not (Test-Path -LiteralPath $absTargetDir -PathType Container -ErrorAction SilentlyContinue)) {
                 Write-Error "'$absTargetDir' (from '$rawTargetDir') is not a valid directory or cannot be accessed." -ErrorAction Continue
                 $retry = Read-Host "Try again? (y/n)"
                 if ($retry -ne 'y') {
                     Write-Host "Exiting this operation."
                     return $null
                 }
                 continue
            }

             if (-not (Test-Path -LiteralPath $absTargetDir -IsValid)) {
                 Write-Warning "Initial check suggests read/execute permissions might be missing for '$absTargetDir'. Scanning will proceed, but errors are possible."
             }
             return $absTargetDir

        } catch [System.Management.Automation.ItemNotFoundException] {
             Write-Error "'$($_.TargetObject)' (from '$rawTargetDir') not found." -ErrorAction Continue
             $retry = Read-Host "Try again? (y/n)"
             if ($retry -ne 'y') {
                Write-Host "Exiting this operation."
                return $null
             }
             continue
        } catch {
             Write-Error "An error occurred resolving path '$rawTargetDir': $($_.Exception.Message)" -ErrorAction Continue
             $retry = Read-Host "Try again? (y/n)"
             if ($retry -ne 'y') {
                 Write-Host "Exiting this operation."
                 return $null
             }
             continue
        }
    }
}

Function Get-YesNoAnswer {
    param(
        [string]$PromptMessage = "Include subdirectories? (y/n)"
    )
    while ($true) {
        $answer = Read-Host -Prompt $PromptMessage
        $answer = $answer.Trim().ToLower()
        if ($answer -eq 'y') {
            return $true
        } elseif ($answer -eq 'n') {
            return $false
        } else {
            Write-Host "Invalid input. Please enter 'y' or 'n'." -ForegroundColor Yellow
        }
    }
}

Function Write-SummarySeparator {
    Write-Host ("-" * 60)
}

Function Cleanup-EmptyOutputFile {
    param (
        [string]$FilePath
    )
    if (Test-Path -LiteralPath $FilePath -PathType Leaf) {
        try {
            $fileInfo = Get-Item -LiteralPath $FilePath -ErrorAction Stop
            if ($fileInfo.Length -eq 0) {
                Remove-Item -LiteralPath $FilePath -Force -ErrorAction Stop
                Write-Host "Removed empty output file: $FilePath"
            }
        } catch {
            Write-Warning "Could not check or remove potentially empty output file '$FilePath': $($_.Exception.Message)"
        }
    }
}

$ScriptDir = Get-ScriptDirectory

while ($true) {

    Write-Host
    Write-SummarySeparator
    Write-Host "File Processing Utility (Requires Administrator)"
    Write-SummarySeparator
    Write-Host "Choose an action:"
    Write-Host "1. Combine Text Files"
    Write-Host "2. List All Files"
    Write-SummarySeparator

    $choice = ""
    while ($choice -notin '1', '2') {
        $choice = Read-Host "Enter your choice (1 or 2)"
        if ($choice -notin '1', '2') {
            Write-Host "Invalid choice. Please enter 1 or 2." -ForegroundColor Yellow
        }
    }

    $targetDir = Get-ValidatedDirectory
    if ($targetDir -eq $null) {
        Write-Host "Operation cancelled by user."
        continue
    }

    $recursiveScan = Get-YesNoAnswer

    $outputFilename = if ($choice -eq '1') { $CombineOutputFilename } else { $ListOutputFilename }
    $outputFilepath = Join-Path -Path $ScriptDir -ChildPath $outputFilename

    Write-Host "`nStarting scan..."

    $processedFiles = 0
    $skippedFiles = 0
    $readErrors = 0
    $accessErrors = 0
    $filesFound = 0

    $GciErrors = [System.Collections.ArrayList]::new()

    $gciParameters = @{
        Path = $targetDir
        File = $true
        ErrorVariable = '+GciErrors'
    }
    if ($recursiveScan) {
        $gciParameters.Recurse = $true
    }

    $fileItems = $null
    try {
        $fileItems = Get-ChildItem @gciParameters -ErrorAction Stop
    } catch [System.UnauthorizedAccessException] {
        Write-Error "Permission denied to access the starting directory '$targetDir'. $($_.Exception.Message)"
        $accessErrors++
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Error "The starting directory '$targetDir' was not found. $($_.Exception.Message)"
    } catch {
        Write-Error "An unexpected error occurred during directory scan setup: $($_.Exception.Message)"
        $accessErrors++
    }

    $accessErrors += $GciErrors.Count
    foreach ($err in $GciErrors) {
         $targetObjectInfo = if ($err.TargetObject) { " ($($err.TargetObject))" } else { "" }
         Write-Warning "Access error during directory scan: $($err.Exception.Message)$targetObjectInfo"
    }

    if ($fileItems -ne $null) {

        if ($choice -eq '1') {
            $combinedContentParts = [System.Collections.Generic.List[string]]::new()
            $totalFilesScanned = @($fileItems).Count

            Write-Host "Identifying and reading text files..."

            foreach ($fileInfo in $fileItems) {
                if (Test-IsLikelyTextFile $fileInfo) {
                    $headerPath = if ($recursiveScan) { $fileInfo.FullName } else { $fileInfo.Name }
                    $header = "$headerPath :`n`n"

                    $fileContent = $null
                    $readWithFallback = $false
                    try {
                        $fileContent = Get-Content -LiteralPath $fileInfo.FullName -Encoding UTF8 -Raw -ErrorAction Stop
                        $processedFiles++
                    } catch [System.Text.DecoderFallbackException] {
                        Write-Host "  Info: File '$($fileInfo.FullName)' not UTF-8. Trying default encoding." -ForegroundColor Cyan
                        try {
                            $fileContent = Get-Content -LiteralPath $fileInfo.FullName -Encoding Default -Raw -ErrorAction Stop
                            Write-Host "  Info: Successfully read '$($fileInfo.FullName)' with fallback encoding." -ForegroundColor Green
                            $readWithFallback = $true
                            $processedFiles++
                        } catch {
                            Write-Warning "Skipping file due to read error (after fallback): '$($fileInfo.FullName)' - Details: $($_.Exception.Message)"
                            $readErrors++
                            $fileContent = $null
                        }
                    } catch [System.UnauthorizedAccessException] {
                         Write-Warning "Skipping file due to permission error: '$($fileInfo.FullName)' - Details: $($_.Exception.Message)"
                         $readErrors++
                    } catch [System.IO.IOException] {
                         Write-Warning "Skipping file due to I/O error (e.g., file in use): '$($fileInfo.FullName)' - Details: $($_.Exception.Message)"
                         $readErrors++
                    } catch {
                         Write-Warning "Skipping file due to unexpected error during read: '$($fileInfo.FullName)' - Details: $($_.Exception.Message)"
                         $readErrors++
                    }

                    if ($fileContent -ne $null) {
                        $combinedContentParts.Add(($header + $fileContent))
                    }
                } else {
                }
            }

            $skippedFiles = $totalFilesScanned - $processedFiles - $readErrors

            Write-SummarySeparator
            Write-Host "Processing Complete (Combine Mode)"
            Write-SummarySeparator
            Write-Host "Files processed and content included: $processedFiles"
            Write-Host "Files skipped (unrecognized extension or non-file): $skippedFiles"
            if ($readErrors -gt 0) {
                Write-Host "Encountered $readErrors error(s) reading file content (check warnings above for details like permissions, encoding, file in use)." -ForegroundColor Yellow
            }
            if ($accessErrors -gt 0) {
                Write-Host "Encountered $accessErrors access error(s) during directory traversal (check warnings above)." -ForegroundColor Yellow
            }

            if ($processedFiles -eq 0) {
                Write-Host "`nNo text files were found and processed in the specified location(s)."
                Cleanup-EmptyOutputFile -FilePath $outputFilepath
            } else {
                $finalOutputString = $combinedContentParts -join "`n`n"
                $outputSize = [System.Text.Encoding]::UTF8.GetByteCount($finalOutputString)
                Write-Host "`nSaving combined content ($('{0:N0}' -f $outputSize) bytes) to: $outputFilepath"
                try {
                    Out-File -FilePath $outputFilepath -InputObject $finalOutputString -Encoding UTF8 -NoNewline -ErrorAction Stop
                    Write-Host "Combined text file saved successfully." -ForegroundColor Green
                } catch [System.UnauthorizedAccessException] {
                    Write-Error "`nError: Permission denied to write the output file '$outputFilepath'.`nPlease check the permissions for the script's directory.`nDetails: $($_.Exception.Message)"
                } catch [System.IO.IOException] {
                    Write-Error "`nError writing output file '$outputFilepath': $($_.Exception.Message)"
                } catch {
                    Write-Error "`nAn unexpected error occurred during output file writing: $($_.Exception.Message)"
                }
            }

        } elseif ($choice -eq '2') {
            $fileList = [System.Collections.Generic.List[string]]::new()
            $filesFound = @($fileItems).Count

            Write-Host "Generating file list..."

            foreach ($fileInfo in $fileItems) {
                 $pathToList = if ($recursiveScan) { $fileInfo.FullName } else { $fileInfo.Name }
                 $fileList.Add($pathToList)
            }

            Write-SummarySeparator
            Write-Host "Processing Complete (List Mode)"
            Write-SummarySeparator
            Write-Host "Found $filesFound file(s)."
            if ($accessErrors -gt 0) {
                 Write-Host "Encountered $accessErrors access/processing error(s) during scan (check warnings above)." -ForegroundColor Yellow
            }

            if ($filesFound -eq 0) {
                $scanLocation = if ($recursiveScan) { "directory and its subdirectories" } else { "specified directory" }
                Write-Host "No files were found in the $scanLocation."
                Cleanup-EmptyOutputFile -FilePath $outputFilepath
            } else {
                Write-Host "`nSaving file list to: $outputFilepath"
                try {
                    Out-File -FilePath $outputFilepath -InputObject $fileList -Encoding UTF8 -ErrorAction Stop
                    Write-Host "File list saved successfully." -ForegroundColor Green
                } catch [System.UnauthorizedAccessException] {
                    Write-Error "`nError: Permission denied to write the output file '$outputFilepath'.`nPlease check write permissions for the script's directory.`nDetails: $($_.Exception.Message)"
                } catch [System.IO.IOException] {
                    Write-Error "`nError writing output file '$outputFilepath': $($_.Exception.Message)"
                } catch {
                    Write-Error "`nAn unexpected error occurred during output file writing: $($_.Exception.Message)"
                }
            }
        }
    } else {
         Write-SummarySeparator
         Write-Host "Processing Complete"
         Write-SummarySeparator
         Write-Host "Directory scanning failed due to initial errors. See messages above."
         Cleanup-EmptyOutputFile -FilePath $outputFilepath
    }

    Write-SummarySeparator
    Write-Host "Returning to main menu..."

}
