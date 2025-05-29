Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.IO.Compression.FileSystem

# --- Debug Logging Start ---
$debugLogPath = Join-Path $env:TEMP "BackupToolIconDebug.log"
Function Write-ToolDebugLog { param([string]$Message) Add-Content -Path $debugLogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message" }
Remove-Item $debugLogPath -ErrorAction SilentlyContinue
Write-ToolDebugLog "Skript gestartet. TEMP-Log unter: $debugLogPath"
# --- Debug Logging End ---

$form = New-Object System.Windows.Forms.Form

# Determine script/EXE directory for icon loading
$scriptDirectory = $null
Write-ToolDebugLog "Initial: scriptDirectory = '$scriptDirectory'"
Write-ToolDebugLog "Initial: PSScriptRoot = '$PSScriptRoot'"
Write-ToolDebugLog "Initial: MyInvocation.MyCommand.Path = '$($MyInvocation.MyCommand.Path)'"
Write-ToolDebugLog "Initial: AppDomain.CurrentDomain.BaseDirectory = '$([System.AppDomain]::CurrentDomain.BaseDirectory)'"

try {
    $executingAssemblyPath = [System.Reflection.Assembly]::GetExecutingAssembly().Location
    Write-ToolDebugLog "Try-Block: executingAssemblyPath = '$executingAssemblyPath'"

    if (-not [string]::IsNullOrWhiteSpace($executingAssemblyPath) -and $executingAssemblyPath.EndsWith(".exe", [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-ToolDebugLog "Try-Block: Als EXE-Pfad erkannt."
        $scriptDirectory = Split-Path $executingAssemblyPath -Parent
        Write-ToolDebugLog "Try-Block: scriptDirectory von EXE-Pfad gesetzt zu '$scriptDirectory'"
    }
    else {
        Write-ToolDebugLog "Try-Block: Kein EXE-Pfad oder executingAssemblyPath leer. Versuche PSScriptRoot."
        if ($PSScriptRoot) {
            $scriptDirectory = $PSScriptRoot
            Write-ToolDebugLog "Try-Block: scriptDirectory von PSScriptRoot gesetzt zu '$scriptDirectory'"
        }
        elseif ($MyInvocation.MyCommand.Path -and ([System.IO.Path]::GetExtension($MyInvocation.MyCommand.Path) -eq ".ps1")) {
             $scriptDirectory = Split-Path $MyInvocation.MyCommand.Path -Parent
             Write-ToolDebugLog "Try-Block: scriptDirectory von MyInvocation gesetzt zu '$scriptDirectory'"
        }
        else {
            Write-ToolDebugLog "Try-Block: PSScriptRoot und MyInvocation ergaben kein Verzeichnis. Versuche AppDomain.CurrentDomain.BaseDirectory."
            try {
                $appDomainBaseDir = [System.AppDomain]::CurrentDomain.BaseDirectory
                Write-ToolDebugLog "Try-Block (AppDomain): AppDomain.CurrentDomain.BaseDirectory = '$appDomainBaseDir'"
                if (-not [string]::IsNullOrWhiteSpace($appDomainBaseDir)) {
                    $scriptDirectory = $appDomainBaseDir.TrimEnd('\') # Entfernt ggf. einen abschließenden Backslash
                    Write-ToolDebugLog "Try-Block (AppDomain): scriptDirectory von AppDomain gesetzt zu '$scriptDirectory'"
                } else {
                    Write-ToolDebugLog "Try-Block (AppDomain): AppDomain.CurrentDomain.BaseDirectory ist leer."
                }
            } catch {
                 Write-ToolDebugLog "Try-Block (AppDomain): Fehler beim Zugriff auf AppDomain.CurrentDomain.BaseDirectory: $($_.Exception.Message)"
            }
        }
    }
}
catch [System.Management.Automation.MethodInvocationException] {
    Write-ToolDebugLog "Catch (MethodInvocationException): $($_.Exception.Message). Fallback-Versuche."
    if ($null -eq $scriptDirectory) {
        if ($PSScriptRoot) {
            $scriptDirectory = $PSScriptRoot
            Write-ToolDebugLog "Catch (MethodInvocationException): scriptDirectory von PSScriptRoot gesetzt zu '$scriptDirectory'"
        }
        elseif ($MyInvocation.MyCommand.Path -and ([System.IO.Path]::GetExtension($MyInvocation.MyCommand.Path) -eq ".ps1")) {
             $scriptDirectory = Split-Path $MyInvocation.MyCommand.Path -Parent
             Write-ToolDebugLog "Catch (MethodInvocationException): scriptDirectory von MyInvocation gesetzt zu '$scriptDirectory'"
        }
        else {
            Write-ToolDebugLog "Catch (MethodInvocationException): Fallback PSScriptRoot und MyInvocation ergaben kein Verzeichnis. Versuche AppDomain."
            try {
                $appDomainBaseDir = [System.AppDomain]::CurrentDomain.BaseDirectory
                Write-ToolDebugLog "Catch (MethodInvocationException - AppDomain): AppDomain.CurrentDomain.BaseDirectory = '$appDomainBaseDir'"
                if (-not [string]::IsNullOrWhiteSpace($appDomainBaseDir)) {
                    $scriptDirectory = $appDomainBaseDir.TrimEnd('\')
                    Write-ToolDebugLog "Catch (MethodInvocationException - AppDomain): scriptDirectory von AppDomain gesetzt zu '$scriptDirectory'"
                } else {
                     Write-ToolDebugLog "Catch (MethodInvocationException - AppDomain): AppDomain.CurrentDomain.BaseDirectory ist leer."
                }
            } catch {
                Write-ToolDebugLog "Catch (MethodInvocationException - AppDomain): Fehler beim Zugriff auf AppDomain.CurrentDomain.BaseDirectory: $($_.Exception.Message)"
            }
        }
    }
}
catch {
    Write-ToolDebugLog "Catch (Allgemeiner Fehler): $($_.Exception.Message). Versuche AppDomain als letzten Ausweg."
     if ($null -eq $scriptDirectory) {
        try {
            $appDomainBaseDir = [System.AppDomain]::CurrentDomain.BaseDirectory
            Write-ToolDebugLog "Catch (Allgemeiner Fehler - AppDomain): AppDomain.CurrentDomain.BaseDirectory = '$appDomainBaseDir'"
            if (-not [string]::IsNullOrWhiteSpace($appDomainBaseDir)) {
                $scriptDirectory = $appDomainBaseDir.TrimEnd('\')
                Write-ToolDebugLog "Catch (Allgemeiner Fehler - AppDomain): scriptDirectory von AppDomain gesetzt zu '$scriptDirectory'"
            } else {
                Write-ToolDebugLog "Catch (Allgemeiner Fehler - AppDomain): AppDomain.CurrentDomain.BaseDirectory ist leer."
            }
        } catch {
            Write-ToolDebugLog "Catch (Allgemeiner Fehler - AppDomain): Fehler beim Zugriff auf AppDomain.CurrentDomain.BaseDirectory: $($_.Exception.Message)"
        }
    }
}

# Finale Prüfung, ob $scriptDirectory immer noch null ist, und letzter Versuch mit AppDomain
if ($null -eq $scriptDirectory) {
    Write-ToolDebugLog "Finale Prüfung vor Icon-Laden: scriptDirectory ist immer noch null. Letzter Versuch mit AppDomain.CurrentDomain.BaseDirectory."
    try {
        $appDomainBaseDir = [System.AppDomain]::CurrentDomain.BaseDirectory
        Write-ToolDebugLog "Finale Prüfung (AppDomain): AppDomain.CurrentDomain.BaseDirectory = '$appDomainBaseDir'"
        if (-not [string]::IsNullOrWhiteSpace($appDomainBaseDir)) {
            $scriptDirectory = $appDomainBaseDir.TrimEnd('\')
            Write-ToolDebugLog "Finale Prüfung (AppDomain): scriptDirectory von AppDomain gesetzt zu '$scriptDirectory'"
        } else {
            Write-ToolDebugLog "Finale Prüfung (AppDomain): AppDomain.CurrentDomain.BaseDirectory ist leer."
        }
    } catch {
        Write-ToolDebugLog "Finale Prüfung (AppDomain): Fehler beim Zugriff auf AppDomain.CurrentDomain.BaseDirectory: $($_.Exception.Message)"
    }
}

Write-ToolDebugLog "Finale Prüfung nach allen Versuchen: scriptDirectory = '$scriptDirectory'"

if (-not [string]::IsNullOrWhiteSpace($scriptDirectory)) {
    Write-ToolDebugLog "Verwende scriptDirectory '$scriptDirectory' für Icon."
    $iconPath = Join-Path $scriptDirectory "icon.ico"
    Write-ToolDebugLog "Icon-Pfad: '$iconPath'"
    if (Test-Path $iconPath -PathType Leaf) {
        Write-ToolDebugLog "Icon-Datei '$iconPath' gefunden."
        try {
            $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)
            Write-ToolDebugLog "Icon erfolgreich zugewiesen."
        }
        catch {
            Write-Warning "Fehler beim Zuweisen des Icons von '$iconPath': $($_.Exception.Message)"
            Write-ToolDebugLog "FEHLER beim Zuweisen des Icons von '$iconPath': $($_.Exception.Message)"
        }
    } else {
        Write-Warning "Icon-Datei 'icon.ico' nicht im Verzeichnis '$scriptDirectory' gefunden oder es ist keine Datei. Es wird ein Standard-Icon verwendet."
        Write-ToolDebugLog "Icon-Datei 'icon.ico' NICHT im Verzeichnis '$scriptDirectory' gefunden oder es ist keine Datei."
    }
} else {
    Write-Warning "Skript-/EXE-Verzeichnis konnte nicht ermittelt werden. Es wird ein Standard-Icon verwendet."
    Write-ToolDebugLog "FEHLER: Skript-/EXE-Verzeichnis konnte NICHT ermittelt werden."
}

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

$form.Text = "Backup and File Tool" # Geänderter Fenstertitel
$form.Size = New-Object System.Drawing.Size(620,450) # Formulargröße angepasst
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle # Fenstergröße nicht änderbar machen
$form.MaximizeBox = $false # Maximize-Button deaktivieren

# TabControl erstellen, um verschiedene Funktionsbereiche zu organisieren
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(10, 10)
$tabControl.Size = New-Object System.Drawing.Size(585, 390) # Größe angepasst
$form.Controls.Add($tabControl)

# TabPage für Backup-Funktionalität
$tabBackup = New-Object System.Windows.Forms.TabPage
$tabBackup.Text = "Backup from ZIP"
$tabControl.TabPages.Add($tabBackup)

# ZIP file Label + TextBox + Button
$labelZip = New-Object System.Windows.Forms.Label
$labelZip.Location = New-Object System.Drawing.Point(10,20)
$labelZip.Size = New-Object System.Drawing.Size(80,20)
$labelZip.Text = "ZIP File:"
$tabBackup.Controls.Add($labelZip) # Zu tabBackup hinzugefügt

$textBoxZip = New-Object System.Windows.Forms.TextBox
$textBoxZip.Location = New-Object System.Drawing.Point(100,18)
$textBoxZip.Size = New-Object System.Drawing.Size(380,20)
$textBoxZip.AllowDrop = $true
$tabBackup.Controls.Add($textBoxZip) # Zu tabBackup hinzugefügt

$buttonBrowseZip = New-Object System.Windows.Forms.Button
$buttonBrowseZip.Location = New-Object System.Drawing.Point(490,16)
$buttonBrowseZip.Size = New-Object System.Drawing.Size(75,23)
$buttonBrowseZip.Text = "Browse"
$tabBackup.Controls.Add($buttonBrowseZip) # Zu tabBackup hinzugefügt

# Backup folder Label + TextBox + Button
$labelBackupFolder = New-Object System.Windows.Forms.Label # Umbenannt zur Klarheit, da $labelBackup bereits für den Tab verwendet wird
$labelBackupFolder.Location = New-Object System.Drawing.Point(10,60)
$labelBackupFolder.Size = New-Object System.Drawing.Size(80,20)
$labelBackupFolder.Text = "Backup Folder:"
$tabBackup.Controls.Add($labelBackupFolder) # Zu tabBackup hinzugefügt

$textBoxBackup = New-Object System.Windows.Forms.TextBox
$textBoxBackup.Location = New-Object System.Drawing.Point(100,58)
$textBoxBackup.Size = New-Object System.Drawing.Size(380,20)
$textBoxBackup.AllowDrop = $true
$tabBackup.Controls.Add($textBoxBackup) # Zu tabBackup hinzugefügt

$buttonBrowseBackup = New-Object System.Windows.Forms.Button
$buttonBrowseBackup.Location = New-Object System.Drawing.Point(490,56)
$buttonBrowseBackup.Size = New-Object System.Drawing.Size(75,23)
$buttonBrowseBackup.Text = "Browse"
$tabBackup.Controls.Add($buttonBrowseBackup) # Zu tabBackup hinzugefügt

# Status Label
$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.Location = New-Object System.Drawing.Point(10, 100)
$labelStatus.Size = New-Object System.Drawing.Size(560, 40) # Breite angepasst
$labelStatus.Text = ""
$tabBackup.Controls.Add($labelStatus) # Zu tabBackup hinzugefügt

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 140)
$progressBar.Size = New-Object System.Drawing.Size(560, 23) # Breite angepasst
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$tabBackup.Controls.Add($progressBar) # Zu tabBackup hinzugefügt

# Create Log File Checkbox
$checkBoxLog = New-Object System.Windows.Forms.CheckBox
$checkBoxLog.Location = New-Object System.Drawing.Point(10, 180)
$checkBoxLog.Size = New-Object System.Drawing.Size(200, 24)
$checkBoxLog.Text = "Create log file"
$tabBackup.Controls.Add($checkBoxLog) # Zu tabBackup hinzugefügt

# Start Button
$buttonStart = New-Object System.Windows.Forms.Button
$buttonStart.Location = New-Object System.Drawing.Point(240, 220) # Y-Position angepasst
$buttonStart.Size = New-Object System.Drawing.Size(100,30)
$buttonStart.Text = "Start Backup"
$tabBackup.Controls.Add($buttonStart) # Zu tabBackup hinzugefügt

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

    if ([string]::IsNullOrWhiteSpace($zipPath)) {
        [System.Windows.Forms.MessageBox]::Show("Der Pfad zur ZIP-Datei darf nicht leer sein.", "Fehler", 'OK', 'Error')
        return
    }
    if (-not (Test-Path $zipPath)) {
        [System.Windows.Forms.MessageBox]::Show("ZIP-Datei nicht gefunden: `"$zipPath`"", "Fehler", 'OK', 'Error')
        return
    }

    if ([string]::IsNullOrWhiteSpace($backupPath)) {
        [System.Windows.Forms.MessageBox]::Show("Der Pfad zum Backup-Ordner darf nicht leer sein.", "Fehler", 'OK', 'Error')
        return
    }
    if (-not (Test-Path $backupPath)) {
        [System.Windows.Forms.MessageBox]::Show("Backup-Ordner nicht gefunden: `"$backupPath`"", "Fehler", 'OK', 'Error')
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
    $form.Refresh() # Stellt sicher, dass die UI aktualisiert wird

    $log = @()
    $entryCount = $entries.Count
    $i = 0

    foreach ($entry in $entries) {
        $i++
        $percent = [math]::Round(($i / $entryCount) * 100)
        $progressBar.Value = $percent
        # $form.Refresh() # Refresh hier kann die Performance stark beeinträchtigen
        $progressBar.Refresh() # Nur die ProgressBar aktualisieren
        $labelStatus.Refresh() # Nur das Label aktualisieren


        if ($entry.FullName -ne "") {
            $targetPath = Join-Path $backupPath $entry.FullName
            $targetDir = [System.IO.Path]::GetDirectoryName($targetPath)
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }

            try {
                $entryStream = $entry.Open()
                # Sicherstellen, dass die Datei überschrieben wird, falls sie existiert
                $fileStream = [System.IO.File]::Create($targetPath) # Überschreibt oder erstellt die Datei
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
                 # Optional: Fehler dem Benutzer anzeigen oder nur loggen
                Write-Warning "Failed to extract $($entry.FullName): $($_.Exception.Message)"
            }
        }
    }

    $zip.Dispose()
    $progressBar.Value = 100 # Sicherstellen, dass die Bar am Ende voll ist
    $labelStatus.Text = "Backup complete!"
    $form.Refresh() # Finale Aktualisierung der UI

    if ($createLog) {
        $logFile = Join-Path $backupPath "backup_log_$(Get-Date -Format yyyyMMdd_HHmmss).txt"
        try {
            $log | Out-File -FilePath $logFile -Encoding UTF8
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to write log file: $($_.Exception.Message)", "Log Error", 'OK', 'Error')
        }
    }

    [System.Windows.Forms.MessageBox]::Show("Backup complete!", "Success", 'OK', 'Information')
})

# TabPage für Datei-Suche und -Manipulation
$tabSearch = New-Object System.Windows.Forms.TabPage
$tabSearch.Text = "File Search & Manage"
$tabControl.TabPages.Add($tabSearch)

# Steuerelemente für den Such-Tab
$labelSearchFolder = New-Object System.Windows.Forms.Label
$labelSearchFolder.Location = New-Object System.Drawing.Point(10, 20)
$labelSearchFolder.Size = New-Object System.Drawing.Size(100, 20)
$labelSearchFolder.Text = "Search Folder:"
$tabSearch.Controls.Add($labelSearchFolder)

$textBoxSearchFolder = New-Object System.Windows.Forms.TextBox
$textBoxSearchFolder.Location = New-Object System.Drawing.Point(120, 18)
$textBoxSearchFolder.Size = New-Object System.Drawing.Size(350, 20)
$textBoxSearchFolder.AllowDrop = $true # Erlaube Drag & Drop für den Ordnerpfad
$tabSearch.Controls.Add($textBoxSearchFolder)

$buttonBrowseSearchFolder = New-Object System.Windows.Forms.Button
$buttonBrowseSearchFolder.Location = New-Object System.Drawing.Point(480, 16)
$buttonBrowseSearchFolder.Size = New-Object System.Drawing.Size(75, 23)
$buttonBrowseSearchFolder.Text = "Browse"
$tabSearch.Controls.Add($buttonBrowseSearchFolder)

$labelSearchTerm = New-Object System.Windows.Forms.Label
$labelSearchTerm.Location = New-Object System.Drawing.Point(10, 50)
$labelSearchTerm.Size = New-Object System.Drawing.Size(100, 30)
$labelSearchTerm.Text = "File Name Contains:"
$tabSearch.Controls.Add($labelSearchTerm)

$textBoxSearchTerm = New-Object System.Windows.Forms.TextBox
$textBoxSearchTerm.Location = New-Object System.Drawing.Point(120, 48)
$textBoxSearchTerm.Size = New-Object System.Drawing.Size(350, 20) # Breite stark erhöht
$tabSearch.Controls.Add($textBoxSearchTerm)

$buttonSearch = New-Object System.Windows.Forms.Button
$buttonSearch.Location = New-Object System.Drawing.Point(480, 45) # Unter die Textbox verschoben
$buttonSearch.Size = New-Object System.Drawing.Size(75, 23)
$buttonSearch.Text = "Search"
$tabSearch.Controls.Add($buttonSearch)

$listBoxResults = New-Object System.Windows.Forms.ListBox
$listBoxResults.Location = New-Object System.Drawing.Point(10, 110) # Nach unten verschoben (vorher 80)
$listBoxResults.Size = New-Object System.Drawing.Size(545, 170) # Höhe angepasst (vorher 200)
$listBoxResults.SelectionMode = [System.Windows.Forms.SelectionMode]::MultiExtended
$tabSearch.Controls.Add($listBoxResults)

$buttonDeleteSelected = New-Object System.Windows.Forms.Button # Umbenannt zur Klarheit
$buttonDeleteSelected.Location = New-Object System.Drawing.Point(10, 290) # Y-Position angepasst (vorher 290, ListBox-Ende ist jetzt 110+170=280)
$buttonDeleteSelected.Size = New-Object System.Drawing.Size(100, 23)
$buttonDeleteSelected.Text = "Delete Selected"
$tabSearch.Controls.Add($buttonDeleteSelected)

# Button "Alle auswählen" für Suchergebnisse
$buttonSelectAll = New-Object System.Windows.Forms.Button
$buttonSelectAll.Location = New-Object System.Drawing.Point(120, 290) # Y-Position angepasst
$buttonSelectAll.Size = New-Object System.Drawing.Size(100, 23)
$buttonSelectAll.Text = "Select All"
$tabSearch.Controls.Add($buttonSelectAll)

# Button "Auswahl aufheben" für Suchergebnisse
$buttonDeselectAll = New-Object System.Windows.Forms.Button
$buttonDeselectAll.Location = New-Object System.Drawing.Point(230, 290) # Y-Position angepasst
$buttonDeselectAll.Size = New-Object System.Drawing.Size(100, 23)
$buttonDeselectAll.Text = "Deselect All"
$tabSearch.Controls.Add($buttonDeselectAll)

# Label für die Anzeige der Anzahl gefundener Dateien
$labelFileCount = New-Object System.Windows.Forms.Label
$labelFileCount.Location = New-Object System.Drawing.Point(10, 320) # Y-Position angepasst (vorher 320, nach den Buttons)
$labelFileCount.Size = New-Object System.Drawing.Size(300, 20)
$labelFileCount.Text = "Files found: 0"
$tabSearch.Controls.Add($labelFileCount)

# Event Handler für Drag & Drop auf textBoxSearchFolder
$textBoxSearchFolder.Add_DragEnter({
    param($sender, $e)
    if ($e.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effect = [Windows.Forms.DragDropEffects]::Copy
    } else {
        $e.Effect = [Windows.Forms.DragDropEffects]::None
    }
})
$textBoxSearchFolder.Add_DragDrop({
    param($sender, $e)
    $files = $e.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    if ($files.Length -gt 0) {
        # Prüfen, ob es ein Ordner ist
        if (Test-Path $files[0] -PathType Container) {
            $textBoxSearchFolder.Text = $files[0]
        } else {
            [System.Windows.Forms.MessageBox]::Show("Please drop a folder, not a file.", "Invalid Drop", 'OK', 'Warning')
        }
    }
})

# Event Handler für Browse Search Folder Button
$buttonBrowseSearchFolder.Add_Click({
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = "Select Folder to Search In"
    $folderDialog.ShowNewFolderButton = $false # Normalerweise will man hier keinen neuen Ordner erstellen
    if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBoxSearchFolder.Text = $folderDialog.SelectedPath
    }
})

# Event Handler für "Alle auswählen" Button
$buttonSelectAll.Add_Click({
    if ($listBoxResults.Items.Count -gt 0) {
        for ($i = 0; $i -lt $listBoxResults.Items.Count; $i++) {
            $listBoxResults.SetSelected($i, $true)
        }
    }
})

# Event Handler für "Auswahl aufheben" Button
$buttonDeselectAll.Add_Click({
    $listBoxResults.ClearSelected()
})

$buttonSearch.Add_Click({
    $searchPath = RemoveQuotes $textBoxSearchFolder.Text
    $searchTerm = $textBoxSearchTerm.Text

    if ([string]::IsNullOrWhiteSpace($searchPath)) {
        [System.Windows.Forms.MessageBox]::Show("Der Pfad zum Suchordner darf nicht leer sein.", "Fehler", 'OK', 'Error')
        return
    }
    if (-not (Test-Path $searchPath -PathType Container)) {
        [System.Windows.Forms.MessageBox]::Show("Suchordner nicht gefunden oder ist kein Verzeichnis: `"$searchPath`"", "Fehler", 'OK', 'Error')
        return
    }
    if ([string]::IsNullOrWhiteSpace($searchTerm)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a search term.", "Info", 'OK', 'Information')
        return
    }

    $listBoxResults.Items.Clear()
    $labelFileCount.Text = "Files found: 0" # Zurücksetzen vor neuer Suche
    try {
        # Suche nach Dateien, deren Name den Suchbegriff enthält (Groß-/Kleinschreibung ignorieren)
        $results = Get-ChildItem -Path $searchPath -Recurse -File | Where-Object { $_.Name -like "*$searchTerm*" }
        if ($results) {
            foreach ($result in $results) {
                $listBoxResults.Items.Add($result.FullName)
            }
            $labelFileCount.Text = "Files found: $($listBoxResults.Items.Count)" # Anzahl aktualisieren
        } else {
            $listBoxResults.Items.Add("No files found matching your criteria.")
            $labelFileCount.Text = "Files found: 0" # Keine Dateien gefunden
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error during search: $($_.Exception.Message)", "Search Error", 'OK', 'Error')
    }
})

$buttonDeleteSelected.Add_Click({
    if ($listBoxResults.SelectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No files selected to delete.", "Info", 'OK', 'Information')
        return
    }

    $confirmResult = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to delete the selected $($listBoxResults.SelectedItems.Count) file(s)?`nThis action cannot be undone.", "Confirm Delete", 'YesNo', 'Warning')
    if ($confirmResult -eq [System.Windows.Forms.DialogResult]::Yes) {
        $deletedCount = 0
        $failedDeletions = @()
        foreach ($itemPath in $listBoxResults.SelectedItems) {
            try {
                Remove-Item -Path $itemPath -Force -ErrorAction Stop
                $deletedCount++
            }
            catch {
                $failedDeletions += $itemPath
                Write-Warning "Failed to delete: $itemPath - $($_.Exception.Message)"
            }
        }

        # ListBox nach dem Löschen aktualisieren
        # Eine einfache Methode ist, die Suche erneut auszuführen oder die gelöschten Elemente manuell zu entfernen
        # Hier entfernen wir die Elemente direkt aus der ListBox
        $itemsToRemove = New-Object System.Collections.ArrayList
        $itemsToRemove.AddRange($listBoxResults.SelectedItems) # Kopieren, da die Collection sich ändert
        foreach($itemToRemove in $itemsToRemove){
            if (-not ($failedDeletions -contains $itemToRemove)){ # Nur entfernen, wenn nicht fehlgeschlagen
                 $listBoxResults.Items.Remove($itemToRemove)
            }
        }
        $labelFileCount.Text = "Files found: $($listBoxResults.Items.Count)" # Anzahl nach dem Löschen aktualisieren
        
        $message = "$deletedCount file(s) deleted successfully."
        if ($failedDeletions.Count -gt 0) {
            $message += "`nCould not delete $($failedDeletions.Count) file(s):`n" + ($failedDeletions -join "`n")
            [System.Windows.Forms.MessageBox]::Show($message, "Deletion Partially Successful", 'OK', 'Warning')
        } else {
            [System.Windows.Forms.MessageBox]::Show($message, "Deletion Successful", 'OK', 'Information')
        }
        
        # Optional: Suche neu ausführen, um die Liste zu aktualisieren, falls gewünscht
        # $buttonSearch.PerformClick() 
    }
})

[void]$form.ShowDialog()