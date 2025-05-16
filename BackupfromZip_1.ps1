Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.IO.Compression.FileSystem

$form = New-Object System.Windows.Forms.Form
$form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Resolve-Path "icon.ico"))


function CleanFileName {
    param([string]$name)
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    foreach ($c in $invalidChars) {
        $name = $name -replace [regex]::Escape($c), '_'
    }
    return $name
}

function CleanPathForNetworkDrive {
    param([string]$path)
    $invalidPathChars = [System.IO.Path]::GetInvalidPathChars() + ':'
    foreach ($c in $invalidPathChars) {
        $path = $path -replace [regex]::Escape($c), '_'
    }
    return $path
}

function Copy-FileWithChecks {
    param (
        [string]$sourceFile,
        [string]$targetFolder
    )

    $fileName = [System.IO.Path]::GetFileName($sourceFile)
    $cleanName = CleanFileName $fileName
    $destPath = Join-Path $targetFolder $cleanName

    if ($targetFolder.StartsWith("\\") -or $targetFolder.StartsWith("//")) {
        $destPath = CleanPathForNetworkDrive $destPath
    }

    try {
        Copy-Item -Path $sourceFile -Destination $destPath -Force
        Write-Host "Copied: $destPath"
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error copying `"$sourceFile`" to `"$destPath`":`n$($_.Exception.Message)", "Error", 'OK', 'Error')
    }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Backup from ZIP"
$form.Size = New-Object System.Drawing.Size(600,320)
$form.StartPosition = "CenterScreen"

# ZIP file Label + TextBox + Button
$labelZip = New-Object System.Windows.Forms.Label
$labelZip.Location = New-Object System.Drawing.Point(10,20)
$labelZip.Size = New-Object System.Drawing.Size(80,20)
$labelZip.Text = "ZIP File:"
$form.Controls.Add($labelZip)

$textBoxZip = New-Object System.Windows.Forms.TextBox
$textBoxZip.Location = New-Object System.Drawing.Point(100,18)
$textBoxZip.Size = New-Object System.Drawing.Size(380,20)
$textBoxZip.AllowDrop = $true
$form.Controls.Add($textBoxZip)

$buttonBrowseZip = New-Object System.Windows.Forms.Button
$buttonBrowseZip.Location = New-Object System.Drawing.Point(490,16)
$buttonBrowseZip.Size = New-Object System.Drawing.Size(75,23)
$buttonBrowseZip.Text = "Browse"
$form.Controls.Add($buttonBrowseZip)

# Backup folder Label + TextBox + Button
$labelBackup = New-Object System.Windows.Forms.Label
$labelBackup.Location = New-Object System.Drawing.Point(10,60)
$labelBackup.Size = New-Object System.Drawing.Size(80,20)
$labelBackup.Text = "Backup Folder:"
$form.Controls.Add($labelBackup)

$textBoxBackup = New-Object System.Windows.Forms.TextBox
$textBoxBackup.Location = New-Object System.Drawing.Point(100,58)
$textBoxBackup.Size = New-Object System.Drawing.Size(380,20)
$textBoxBackup.AllowDrop = $true
$form.Controls.Add($textBoxBackup)

$buttonBrowseBackup = New-Object System.Windows.Forms.Button
$buttonBrowseBackup.Location = New-Object System.Drawing.Point(490,56)
$buttonBrowseBackup.Size = New-Object System.Drawing.Size(75,23)
$buttonBrowseBackup.Text = "Browse"
$form.Controls.Add($buttonBrowseBackup)

# Status Label
$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.Location = New-Object System.Drawing.Point(10, 100)
$labelStatus.Size = New-Object System.Drawing.Size(560, 40)
$labelStatus.Text = ""
$form.Controls.Add($labelStatus)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 140)
$progressBar.Size = New-Object System.Drawing.Size(560, 23)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$form.Controls.Add($progressBar)

# Create Log File Checkbox
$checkBoxLog = New-Object System.Windows.Forms.CheckBox
$checkBoxLog.Location = New-Object System.Drawing.Point(10, 180)
$checkBoxLog.Size = New-Object System.Drawing.Size(200, 24)
$checkBoxLog.Text = "Create log file"
$form.Controls.Add($checkBoxLog)

# Start Button
$buttonStart = New-Object System.Windows.Forms.Button
$buttonStart.Location = New-Object System.Drawing.Point(240, 210)
$buttonStart.Size = New-Object System.Drawing.Size(100,30)
$buttonStart.Text = "Start Backup"
$form.Controls.Add($buttonStart)

# DragEnter event handler for ZIP TextBox
$textBoxZip.Add_DragEnter({
    param($sender, $e)
    if ($e.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effect = [Windows.Forms.DragDropEffects]::Copy
    } else {
        $e.Effect = [Windows.Forms.DragDropEffects]::None
    }
})

# DragDrop event handler for ZIP TextBox
$textBoxZip.Add_DragDrop({
    param($sender, $e)
    $files = $e.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    if ($files.Length -gt 0) {
        $textBoxZip.Text = $files[0]
    }
})

# DragEnter event handler for Backup Folder TextBox
$textBoxBackup.Add_DragEnter({
    param($sender, $e)
    if ($e.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effect = [Windows.Forms.DragDropEffects]::Copy
    } else {
        $e.Effect = [Windows.Forms.DragDropEffects]::None
    }
})

# DragDrop event handler for Backup Folder TextBox
$textBoxBackup.Add_DragDrop({
    param($sender, $e)
    $files = $e.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    if ($files.Length -gt 0) {
        $textBoxBackup.Text = $files[0]
    }
})

# ZIP Browse Button Event
$buttonBrowseZip.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "ZIP files (*.zip)|*.zip"
    $dialog.Title = "Select ZIP File"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBoxZip.Text = $dialog.FileName
    }
})

# Backup Folder Browse Button Event
$buttonBrowseBackup.Add_Click({
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = "Select Backup Folder"
    $folderDialog.ShowNewFolderButton = $true
    if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBoxBackup.Text = $folderDialog.SelectedPath
    }
})

# Helper function to trim quotes from paths
function RemoveQuotes {
    param([string]$path)
    return $path.Trim('"')
}

$buttonStart.Add_Click({
    $zipPath = RemoveQuotes $textBoxZip.Text
    $backupPath = RemoveQuotes $textBoxBackup.Text
    $createLog = $checkBoxLog.Checked

    if (-not (Test-Path $zipPath)) {
        [System.Windows.Forms.MessageBox]::Show("ZIP file not found.", "Error", 'OK', 'Error')
        return
    }

    if (-not (Test-Path $backupPath)) {
        [System.Windows.Forms.MessageBox]::Show("Backup folder not found.", "Error", 'OK', 'Error')
        return
    }

    # Check if ZIP file is valid
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to open ZIP file. It may be corrupted.", "Error", 'OK', 'Error')
        return
    }

    $entries = $zip.Entries
    $totalSize = ($entries | Measure-Object Length -Sum).Sum

    $drive = Get-PSDrive -Name ($backupPath.Substring(0,1)) -ErrorAction SilentlyContinue
    if ($drive -and $drive.Free -lt $totalSize) {
        [System.Windows.Forms.MessageBox]::Show("Not enough free space available.`nRequired: $([math]::Round($totalSize/1MB,2)) MB`nAvailable: $([math]::Round($drive.Free/1MB,2)) MB", "Insufficient Space", 'OK', 'Warning')
        $zip.Dispose()
        return
    }

    $progressBar.Value = 0
    $labelStatus.Text = "Backup in progress..."
    $form.Refresh()

    $log = @()
    $entryCount = $entries.Count
    $i = 0

    foreach ($entry in $entries) {
        $i++
        $percent = [math]::Round(($i / $entryCount) * 100)
        $progressBar.Value = $percent
        $form.Refresh()

        if ($entry.FullName -ne "") {
            $targetPath = Join-Path $backupPath $entry.FullName
            $targetDir = [System.IO.Path]::GetDirectoryName($targetPath)
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }

            try {
                $entryStream = $entry.Open()
                $fileStream = [System.IO.File]::Create($targetPath)
                $entryStream.CopyTo($fileStream)
                $entryStream.Dispose()
                $fileStream.Dispose()

                if ($createLog) {
                    $log += "Extracted: $($entry.FullName)"
                }
            }
            catch {
                if ($createLog) {
                    $log += "Failed: $($entry.FullName) - $($_.Exception.Message)"
                }
            }
        }
    }

    $zip.Dispose()
    $progressBar.Value = 0
    $labelStatus.Text = "Backup complete!"

    if ($createLog) {
        $logFile = Join-Path $backupPath "backup_log_$(Get-Date -Format yyyyMMdd_HHmmss).txt"
        $log | Out-File -FilePath $logFile -Encoding UTF8
    }

    [System.Windows.Forms.MessageBox]::Show("Backup complete!", "Success", 'OK', 'Information')
})

[void]$form.ShowDialog()
