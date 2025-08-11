# Demander à l'utilisateur le chemin du fichier de sauvegarde
$FilePath = Read-Host -Prompt "Entrez le chemin du fichier de sauvegarde à importer (.reg)"

# Vérifier si le fichier existe
if (-Not (Test-Path $FilePath)) {
    Write-Host "Le fichier spécifié n'existe pas. Vérifiez le chemin." -ForegroundColor Red
    exit
}

# Définir le chemin de la clé à supprimer
$RegistryPath = "HKEY_CURRENT_USER\SOFTWARE\Tracker Software\PDFXEditor\3.0\Settings"

# Supprimer la configuration existante
Write-Host "Suppression de la configuration actuelle..."
Remove-Item -Path "HKCU:\SOFTWARE\Tracker Software\PDFXEditor\3.0\Settings" -Recurse -ErrorAction SilentlyContinue

# Importer la configuration depuis le fichier
Write-Host "Importation de la nouvelle configuration..."
reg import $FilePath

Write-Host "Configuration importée avec succès depuis $FilePath"
