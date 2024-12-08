# Backup PDFXChange Configuration

This script allows you to back up the configuration of **PDFXChange Editor** by exporting the relevant registry keys and saving the `%appdata%\Tracker Software` directory into a compressed `.zip` file.

## Features

- Exports the registry key containing the PDFXChange settings as a `.reg` file.
- Archives the `.reg` file and the `%appdata%\Tracker Software` directory into a `.zip` file.
- Automatically names the `.zip` file with the current date for easy organization.

## Prerequisites

- Windows PowerShell 5.0 or later (for `Compress-Archive` support).
- Sufficient permissions to access registry keys and the `%appdata%` directory.

## Installation

1. Download the script `Backup_PDFXChange_Config.ps1`.
2. Place the script in a directory of your choice.

## Usage

1. Open PowerShell.
2. Navigate to the directory containing the script using `cd`.
3. Run the script:
   ```powershell
   .\Backup_PDFXChange_Config.ps1
   ```
4. The backup `.zip` file will be saved in your **Documents** folder.

## Troubleshooting: Script Execution Policy

If you encounter an error stating that script execution is not authorized, you may need to adjust your PowerShell execution policy. 

### Steps to Allow Script Execution

1. Open PowerShell as an administrator.
2. Check the current execution policy:
   ```powershell
   Get-ExecutionPolicy
   ```
3. Temporarily allow script execution for the current session:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```
4. Run the script as described above.

Alternatively, to permanently allow scripts:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

> **Note:** Be cautious when changing the execution policy, especially if your system is part of a managed environment. Always reset it to a more restrictive policy (`Restricted` or `AllSigned`) after completing your tasks if necessary.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Disclaimer

This script is provided "as-is" without warranty of any kind. Use it at your own risk.
