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
# =====================================================================================

<#
.SYNOPSIS
    Restaure la configuration de PDF-XChange Editor depuis une archive de sauvegarde.

.DESCRIPTION
    Ce script prend en entrée le chemin d'une archive ZIP créée par le script de sauvegarde.
    Il décompresse l'archive, importe les paramètres depuis le fichier .reg et restaure le dossier de configuration
    dans AppData.

    ATTENTION : Cette opération est destructive et écrasera votre configuration actuelle de PDF-XChange Editor.
    Il est recommandé de fermer l'application avant de lancer la restauration.

.PARAMETER Path
    Chemin d'accès obligatoire vers le fichier de sauvegarde .zip à restaurer.

.EXAMPLE
    PS C:\> .\Restore-PDFXChangeConfig.ps1 -Path "C:\Users\monnom\Documents\PDFXChange_Backup_2025-08-11.zip"
    Restaure la configuration depuis le fichier spécifié. Une demande de confirmation sera affichée.

.EXAMPLE
    PS C:\> .\Restore-PDFXChangeConfig.ps1 -Path "C:\backups\backup.zip" -WhatIf
    Affiche ce que le script ferait (importer le registre, copier les fichiers) sans réellement exécuter les actions.

.NOTES
    ConfirmImpact est défini sur 'High', ce qui signifie que PowerShell demandera automatiquement une confirmation
    pour cette action potentiellement destructive. Pour passer outre, utilisez `-Confirm:$false`.
#>
function Restore-PDFXChangeConfig {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]
        $Path
    )

    # --- 1. Validation des paramètres ---
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        throw "Le fichier '$Path' n'a pas été trouvé ou n'est pas un fichier."
    }
    if (-not $Path.EndsWith('.zip', [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Le fichier spécifié n'est pas une archive .zip."
    }

    # --- 2. Création d'un environnement temporaire sécurisé ---
    $tempUnzipPath = Join-Path $env:TEMP ([guid]::NewGuid().ToString())
    
    try {
        # --- 3. Confirmation et logique principale ---
        $targetDescription = "la configuration de PDF-XChange Editor depuis '$Path'"
        $actionDescription = "Restauration des paramètres"
        
        if ($PSCmdlet.ShouldProcess($targetDescription, $actionDescription)) {
            
            Write-Verbose "Création du dossier temporaire : $tempUnzipPath"
            New-Item -ItemType Directory -Path $tempUnzipPath | Out-Null

            Write-Verbose "Décompression de l'archive '$Path'..."
            Expand-Archive -Path $Path -DestinationPath $tempUnzipPath -Force

            # Recherche des éléments de la sauvegarde
            $regFile = Get-ChildItem -Path $tempUnzipPath -Filter *.reg | Select-Object -First 1
            $sourceAppDir = Get-ChildItem -Path $tempUnzipPath -Directory -Filter "Tracker Software" | Select-Object -First 1

            if (-not $regFile) {
                throw "Aucun fichier .reg trouvé dans l'archive."
            }
            if (-not $sourceAppDir) {
                throw "Le dossier 'Tracker Software' n'a pas été trouvé dans l'archive."
            }

            # --- Restauration ---
            Write-Verbose "Importation du fichier de registre : $($regFile.Name)"
            # Les guillemets protègent contre les espaces dans les chemins
            reg.exe import "$($regFile.FullName)"

            $appDataTarget = Join-Path $env:APPDATA "Tracker Software"
            Write-Verbose "Restauration du dossier de configuration vers '$appDataTarget'"
            
            # Suppression de l'ancienne configuration avant de copier la nouvelle
            if(Test-Path $appDataTarget) {
                Write-Verbose "Suppression de la configuration existante..."
                Remove-Item -Path $appDataTarget -Recurse -Force
            }
            
            Copy-Item -Path $sourceAppDir.FullName -Destination $env:APPDATA -Recurse -Force

            Write-Host "✅ Restauration terminée avec succès." -ForegroundColor Green
            Write-Host "Veuillez redémarrer PDF-XChange Editor pour que les changements prennent effet."
        }
    }
    catch {
        Write-Error "❌ Échec de la restauration : $($_.Exception.Message)"
    }
    finally {
        # --- Nettoyage systématique du dossier temporaire ---
        if (Test-Path $tempUnzipPath) {
            Write-Verbose "Nettoyage des fichiers temporaires..."
            Remove-Item -Path $tempUnzipPath -Recurse -Force
        }
    }
}

# =====================================================================================
# --- APPEL DE LA FONCTION PRINCIPALE ---
# Cette ligne exécute la fonction définie ci-dessus et lui transmet les paramètres.
# =====================================================================================
Restore-PDFXChangeConfig @PSBoundParameters
