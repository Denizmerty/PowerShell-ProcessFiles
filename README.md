# File Processing Utility

This PowerShell script helps you work with files within a specific folder(and optionally its subfolders). It offers two main functions:

1.  **Combine Text Files:** Finds common text-based files(like `.txt`, `.log`, `.csv`, `.md`, source code files, configuration files, etc.) and merges their content into a single output file. Each file's content is separated by its path. This makes Ctrl + F'ing stuff easier.
2.  **List All Files:** Creates a simple list of *all* files found in the specified location(s). This also provides a fast way to see whether or not a specified file exists there, rather than relying on slow Windows search or a third party tool like "Everything".

## Features

*   Easy-to-use menu to choose between combining text files or listing all files.
*   Optionally scan subdirectories within your chosen folder.
*   Recognizes a wide range of common text file extensions and specific filenames(like `Makefile`, `Dockerfile`, `requirements.txt`).
*   Attempts to read files using standard text encodings(UTF-8 first, then a fallback).
*   Provides feedback on progress and summarizes the results, including any errors encountered(like permission issues or files that couldn't be read).
*   Saves the results to clearly named files(`combined_text_files.txt` or `file_list.txt`) in the same directory where the script is located.

## Requirements

*   **Windows Operating System**
*   **PowerShell Version 5.1 or higher**(this usually comes pre-installed on Windows 10 and later).
*   **Administrator Privileges:** The script needs to be run "as Administrator". This is required to potentially access files in system-protected areas or other user directories if you choose to scan them. The script will check for this and stop if not run with administrator rights.

## How to Use

1.  **Save the script:** Save the code to a file named something like `ProcessFiles.ps1`.
2.  **Run as Administrator:**
    *   Right-click the PowerShell icon in your Start Menu or search bar.
    *   Select "Run as administrator".
    *   In the Administrator PowerShell window that opens, navigate to the directory where you saved the script using the `cd` command. For example:
        ```powershell
        cd C:\Users\YourUsername\Scripts
        ```
    *   Run the script by typing its name:
        ```powershell
        .\ProcessFiles.ps1
        ```
3.  **Follow Prompts:**
    *   The script will display a menu. Enter `1` to combine text files or `2` to list all files.
    *   You will be asked to enter the full path to the directory you want to scan.
    *   You will be asked if you want to include subdirectories(`y` for yes, `n` for no).
    *   The script will then process the files and show a summary.

## Output Files

The script will create one of the following files in the **same directory where the script itself is located**:

*   `combined_text_files.txt`: Created when you choose option 1. Contains the content of all recognized text files, each section preceded by the file's path(e.g., `C:\MyProject\README.md :`).
*   `file_list.txt`: Created when you choose option 2. Contains a plain list of the full paths of all files found.

If no relevant files are found or processed, the script might remove an empty output file to avoid clutter.

## Important Notes

*   **Administrator Rights:** Running as administrator is necessary for the script to have the best chance of accessing all the files you intend to scan without permission errors.
*   **Text File Recognition:** The script identifies "text files" based on a built-in list of common extensions(like `.txt`, `.py`, `.js`, `.log`, `.json`, `.xml`, etc.) and specific known filenames. It will *not* attempt to read binary files like images(`.jpg`), executables(`.exe`), or complex formats like Word documents(`.docx`).
*   **Errors:** If the script encounters errors(e.g., it doesn't have permission to read a specific file, or a file is locked by another program), it will report a warning and skip that file, continuing with the rest. Check the on-screen messages for details.

## Running without Administrator Privileges(Optional)

If you do not have administrator privileges or prefer not to use them, you can modify the script to bypass the check. However, be aware that the script might then fail to access certain files or directories due to insufficient permissions, resulting in more "access error" warnings.

1.  Open the `ProcessFiles.ps1` script in a text editor.
2.  Find the block of code near the beginning that checks for administrator rights. It looks like this:
    ```powershell
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $windowsPrincipal = [System.Security.Principal.WindowsPrincipal]$currentUser

    if(-not $windowsPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script requires Administrator privileges to run. Please right-click on the PowerShell executable and select 'Run as administrator' before running this script."
        Read-Host "Press Enter to exit..."
        exit 1
    }
    ```
3.  You can either **delete** this entire block or **comment it out** by adding a `#` symbol at the beginning of each line within the block.
4.  Save the modified script. It should now run without requiring administrator elevation, but its ability to scan all potential locations might be limited by your standard user account's permissions.