# PowerShell Backup Tool

A lightweight and user-friendly backup utility written in PowerShell with a graphical user interface (GUI).  
This tool allows you to back up files and folders to a selected destination with support for drag & drop, free space check, logging, and more.

## 🧰 Features

- Drag & drop support for file and folder selection
- Checks if enough disk space is available before starting the backup
- Displays backup progress with file names
- Optional logging to a file
- Remembers last used source and destination paths
- Simple and clean user interface
- Supports paths wrapped in quotation marks (`"C:\My Folder"`)

## ✅ Requirements

- Windows PowerShell 5.1 or later
- .NET Framework (included in most modern Windows systems)

## 🚀 Getting Started

1. Clone or download the repository.
2. Run the script:

```powershell
.\BackupTool.ps1

    💡 Make sure you unblock the script if downloaded from the internet:
    Right-click → Properties → "Unblock" checkbox → Apply

⚙️ Optional: Convert to EXE

To create an .exe from this PowerShell script:

ps2exe.ps1 -inputFile .\BackupTool.ps1 -outputFile .\BackupTool.exe -iconFile .\icon.ico

📁 Log File

If logging is enabled (via checkbox in the GUI), a file named backup_log.txt will be created in the script directory, containing details of copied files and any errors.
📸 Screenshot


![Screenshot 2025-05-16 160127](https://github.com/user-attachments/assets/41dd2348-b295-47ab-803d-bd5c3721909c)
