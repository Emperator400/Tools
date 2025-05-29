# Backup and File Tool Documentation

## Overview
The Backup and File Tool is a PowerShell script designed to provide a user-friendly graphical interface for two main functionalities:
1.  **Backup from ZIP**: Allows users to select a ZIP file, specify a backup folder, and perform the backup operation with real-time progress updates and error handling.
2.  **File Search & Manage**: Enables users to search for files within a specified folder based on a name-containing term and delete selected files.

The tool uses a tabbed interface to separate these functionalities.

## Features
- **Tabbed Interface**: Organizes "Backup from ZIP" and "File Search & Manage" into separate tabs.
- **Backup from ZIP**:
    - **Select ZIP File**: Users can browse and select a ZIP file to back up.
    - **Specify Backup Folder**: Users can choose the destination folder for the backup.
    - **Progress Updates**: The tool provides visual feedback on the backup progress.
    - **Error Handling**: Users are notified of any errors that occur during the backup process.
    - **Log File Creation**: Option to create a log file detailing the backup process.
- **File Search & Manage**:
    - **Select Search Folder**: Users can browse or drag-and-drop a folder to search within.
    - **Search by File Name**: Users can input a term to find files whose names contain that term.
    - **Display Results**: Found files are listed, showing their full paths.
    - **File Count**: Displays the number of files found.
    - **Select/Deselect All**: Buttons to quickly select or deselect all files in the results.
    - **Delete Selected Files**: Users can delete one or more selected files from the search results with a confirmation prompt.
    - 
 ![grafik](https://github.com/user-attachments/assets/7e673c1a-8338-4ce2-89ce-4e1e57aaf0b2)

 ![grafik](https://github.com/user-attachments/assets/c9826dc6-e0d5-4f4f-a145-94e43b4c35fe)


## Prerequisites
- Windows operating system with PowerShell installed.
- .NET Framework (required for Windows Forms).
- Access to the file system for reading ZIP files, writing backups, searching folders, and deleting files.

## How to Use
1.  **Run the Script**: Open PowerShell and execute the `BackupfromZip_1.ps1` script, or run the compiled `BackupAndFileTool.exe`.
2.  **Navigate Tabs**:
    *   Use the "Backup from ZIP" tab for backup operations.
    *   Use the "File Search & Manage" tab for finding and deleting files.
3. Convert from .ps1 to .exe
   ```Powershell
   ps2exe -inputFile BackupfromZip_1.ps1" -outputFile "BackupAndFileTool.exe" -iconFile "icon.ico" -title "Backup and File Tool" -version "1.0.0.0" -noConsole
   ```

### Backup from ZIP Tab
1.  **Select ZIP File**: Click the "Browse" button next to the "ZIP File" label (or drag and drop a ZIP file onto the textbox) to select the ZIP file you want to back up.
2.  **Choose Backup Folder**: Click the "Browse" button next to the "Backup Folder" label (or drag and drop a folder onto the textbox) to specify where you want to save the backup.
3.  **Log File Option**: If desired, check the "Create log file" checkbox to generate a log of the backup process.
4.  **Start Backup**: Click the "Start Backup" button to begin the backup process. Monitor the progress bar for updates.

### File Search & Manage Tab
1.  **Select Search Folder**: Click the "Browse" button next to the "Search Folder:" label (or drag and drop a folder onto the textbox) to choose the directory you want to search in.
2.  **Enter Search Term**: In the "File Name Contains:" textbox, type the text you want to find within file names.
3.  **Start Search**: Click the "Search" button.
4.  **Review Results**: The list box will populate with files matching your criteria. The "Files found:" label will update.
5.  **Manage Files**:
    *   Select files in the list (use Ctrl-click for multiple individual files, Shift-click for a range, or the "Select All" / "Deselect All" buttons).
    *   Click "Delete Selected" to remove the chosen files. You will be asked for confirmation.

## Notes
- Ensure that you have sufficient disk space in the backup location.
- The tool will notify you if the ZIP file is invalid or if there are any issues during the backup or file operations.
- Deleting files is a permanent action. Be sure you want to remove them.
