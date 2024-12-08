# Définir le chemin de la clé de registre à exporter
$RegistryPath = "HKEY_CURRENT_USER\SOFTWARE\Tracker Software\PDFXEditor\3.0\Settings"

# Obtenir le dossier Documents de l'utilisateur courant
$DocumentsFolder = [Environment]::GetFolderPath("MyDocuments")

# Générer un nom de fichier avec la date au format ISO
$DateISO = (Get-Date).ToString("yyyy-MM-dd")
$FileName = "PDFXChange_Settings_$DateISO.reg"
$ExportFilePath = Join-Path -Path $DocumentsFolder -ChildPath $FileName

# Exporter la clé de registre
reg export $RegistryPath $ExportFilePath /y

Write-Host "Configuration exportée vers $ExportFilePath"
