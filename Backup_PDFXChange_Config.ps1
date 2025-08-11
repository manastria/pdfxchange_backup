# =====================================================================================
# INSTRUCTIONS EN CAS DE BLOCAGE PAR LA POLITIQUE D'EXÉCUTION
#
# Si l'exécution de ce script est bloquée par une erreur de sécurité, cela signifie
# que la politique d'exécution de PowerShell est trop restrictive.
#
# Pour autoriser l'exécution des scripts locaux pour votre utilisateur (recommandé),
# ouvrez une console PowerShell et exécutez la commande suivante :
#
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#
# Vous pouvez aussi contourner la politique pour une seule exécution avec :
# powershell.exe -ExecutionPolicy Bypass -File ".\Backup-PDFXChangeConfig.ps1"
#
# =====================================================================================

<#
.SYNOPSIS
    Sauvegarde la configuration de PDF-XChange Editor.

.DESCRIPTION
    Ce script exporte la clé de registre de configuration de PDF-XChange Editor et sauvegarde le dossier de configuration
    situé dans AppData. Il compresse ensuite ces deux éléments dans une archive ZIP unique et horodatée.
    Le script détecte automatiquement la version du logiciel installée.

.PARAMETER DestinationPath
    Spécifie le dossier où l'archive de sauvegarde (.zip) sera enregistrée.
    Par défaut, il s'agit du dossier "Documents" de l'utilisateur courant.

.PARAMETER Force
    Si ce commutateur est présent, le script écrasera une sauvegarde existante portant le même nom.
    Sinon, il s'arrêtera avec une erreur si le fichier de destination existe déjà.

.OUTPUTS
    System.IO.FileInfo
    Retourne l'objet fichier de l'archive ZIP créée.

.EXAMPLE
    PS C:\> .\Backup-PDFXChangeConfig.ps1
    Sauvegarde la configuration dans le dossier Documents de l'utilisateur.

.EXAMPLE
    PS C:\> .\Backup-PDFXChange-Config.ps1 -DestinationPath "D:\Backups" -Force
    Sauvegarde la configuration dans D:\Backups et écrase toute sauvegarde existante du même jour.

.NOTES
    POLITIQUE D'EXÉCUTION (EXECUTION POLICY) :
    Si l'exécution de ce script échoue avec un message concernant l'autorisation, il est probable que la politique
    d'exécution de PowerShell soit la cause. Pour la vérifier, utilisez `Get-ExecutionPolicy`.
    
    Pour autoriser ce script à s'exécuter, la solution recommandée est de définir la politique à `RemoteSigned`
    pour l'utilisateur actuel avec la commande :
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#>

function Backup-PDFXChangeConfig {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory = $false)]
        [string]
        $DestinationPath = [Environment]::GetFolderPath("MyDocuments"),

        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )

    try {
        # --- 1. Détection dynamique des chemins ---
        Write-Verbose "Détection de la configuration de PDF-XChange Editor..."
        
        $baseRegKeyPath = "HKCU:\SOFTWARE\Tracker Software\PDFXEditor"
        
        if (-not (Test-Path -Path $baseRegKeyPath)) {
            throw "La clé de registre de base '$baseRegKeyPath' n'a pas été trouvée. PDF-XChange Editor est-il bien installé pour cet utilisateur ?"
        }

        $versionKey = Get-ChildItem -Path $baseRegKeyPath -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $versionKey) {
            throw "La clé '$baseRegKeyPath' a été trouvée, mais elle ne contient aucune sous-clé de version (ex: 3.0, 9.0, etc.). La configuration est peut-être incomplète."
        }
        
        # --- CORRECTION FINALE : Utiliser .Name au lieu de .PSPath pour la compatibilité avec reg.exe ---
        $registryPath = $versionKey.Name

        $sourceDirectory = Join-Path $env:APPDATA "Tracker Software"
        if (-not (Test-Path $sourceDirectory)) {
            throw "Le dossier de configuration '$sourceDirectory' n'a pas été trouvé."
        }
        
        Write-Verbose "Clé de registre trouvée pour reg.exe : $registryPath"
        Write-Verbose "Dossier de configuration trouvé : $sourceDirectory"

        # --- 2. Définition des noms de fichiers ---
        $dateISO = (Get-Date).ToString("yyyy-MM-dd")
        $zipFileName = "PDFXChange_Backup_$dateISO.zip"
        $zipFilePath = Join-Path -Path $DestinationPath -ChildPath $zipFileName
        
        $tempRegFileName = "PDFXChange_Settings_$($env:COMPUTERNAME)_$dateISO.reg"
        $tempRegFilePath = Join-Path -Path $env:TEMP -ChildPath $tempRegFileName

        # --- 3. Gestion des conflits ---
        if ((Test-Path $zipFilePath) -and -not $Force) {
            throw "Le fichier de sauvegarde '$zipFilePath' existe déjà. Utilisez le paramètre -Force pour l'écraser."
        }

        # --- 4. Logique de sauvegarde avec nettoyage ---
        try {
            Write-Verbose "Exportation de la clé de registre '$registryPath' vers un fichier temporaire..."
            if ($PSCmdlet.ShouldProcess($registryPath, "Exportation de la clé de registre")) {
                # Mettre le chemin entre guillemets pour reg.exe au cas où il contiendrait des espaces
                reg.exe export "$registryPath" "$tempRegFilePath" /y
            }
            
            # Vérification que le fichier .reg a bien été créé avant de continuer
            if (-not (Test-Path $tempRegFilePath)) {
                throw "L'exportation du registre a échoué. Le fichier .reg temporaire n'a pas été créé."
            }

            $itemsToCompress = @($tempRegFilePath, $sourceDirectory)
            Write-Verbose "Compression des éléments dans '$zipFilePath'..."
            if ($PSCmdlet.ShouldProcess($zipFilePath, "Création de l'archive ZIP")) {
                Compress-Archive -Path $itemsToCompress -DestinationPath $zipFilePath -Force
            }
        }
        finally {
            if (Test-Path $tempRegFilePath) {
                Write-Verbose "Nettoyage du fichier de registre temporaire : $tempRegFilePath"
                Remove-Item $tempRegFilePath -Force
            }
        }
        
        # --- 5. Sortie et confirmation ---
        Write-Host "✅ La configuration a été sauvegardée avec succès dans :" -ForegroundColor Green
        Write-Host $zipFilePath
        return Get-Item -Path $zipFilePath
    }
    catch {
        Write-Error "❌ Échec de la sauvegarde : $($_.Exception.Message)"
    }
}

# =====================================================================================
# --- APPEL DE LA FONCTION PRINCIPALE ---
# =====================================================================================
Backup-PDFXChangeConfig @PSBoundParameters