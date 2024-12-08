# Définir la clé de registre à exporter
$RegistryPath = "HKEY_CURRENT_USER\SOFTWARE\Tracker Software\PDFXEditor\3.0\Settings"

# Obtenir le dossier Documents de l'utilisateur courant
$DocumentsFolder = [Environment]::GetFolderPath("MyDocuments")

# Obtenir le dossier AppData de l'utilisateur courant
$AppDataFolder = $env:AppData

# Définir le dossier à sauvegarder (configuration PDFXChange)
$SourceDirectory = Join-Path $AppDataFolder "Tracker Software"

# Générer une date au format ISO
$DateISO = (Get-Date).ToString("yyyy-MM-dd")

# Nom du fichier .reg exporté
$RegFileName = "PDFXChange_Settings_$DateISO.reg"
$RegExportFilePath = Join-Path -Path $DocumentsFolder -ChildPath $RegFileName

# Exporter la clé de registre
reg export $RegistryPath $RegExportFilePath /y

# Nom du fichier ZIP final
$ZipFileName = "PDFXChange_Backup_$DateISO.zip"
$ZipFilePath = Join-Path -Path $DocumentsFolder -ChildPath $ZipFileName

# Si le fichier ZIP existe déjà, on le supprime
if (Test-Path $ZipFilePath) {
    Remove-Item $ZipFilePath -Force
}

# Compresser le fichier .reg et le dossier dans un .zip
# Compress-Archive permet de spécifier plusieurs sources
Compress-Archive -Path $RegExportFilePath, $SourceDirectory -DestinationPath $ZipFilePath

Write-Host "La configuration a été sauvegardée dans $ZipFilePath"
