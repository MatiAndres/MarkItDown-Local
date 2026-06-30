$ErrorActionPreference = "Stop"
$Launcher = Join-Path $PSScriptRoot "MarkItDown.ps1"

Write-Host "Preparando MarkItDown Local..."
& $Launcher -Diagnose

