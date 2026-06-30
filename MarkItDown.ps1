param(
    [string]$Source,
    [string]$Output,
    [switch]$Open,
    [switch]$Overwrite,
    [switch]$Silent,
    [switch]$Diagnose
)

$ErrorActionPreference = "Stop"
$Launcher = Join-Path $PSScriptRoot "scripts\MarkItDown.ps1"

if (-not (Test-Path $Launcher)) {
    Write-Error "No se encontro el launcher principal en: $Launcher"
    exit 1
}

& $Launcher @PSBoundParameters
exit $LASTEXITCODE

