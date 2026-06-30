param(
    [string]$Source,
    [string]$Output,
    [switch]$Open,
    [switch]$Overwrite,
    [switch]$Silent,
    [switch]$Diagnose
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$VenvDir = Join-Path $ProjectRoot ".venv"
$VenvPython = Join-Path $VenvDir "Scripts\python.exe"
$ConfigPath = Join-Path $ProjectRoot "config\config.json"
$ConverterPath = Join-Path $ProjectRoot "src\convertir_markitdown.py"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[ADVERTENCIA] $Message" -ForegroundColor Yellow
}

function Fail {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    exit 1
}

function Load-Config {
    if (-not (Test-Path $ConfigPath)) {
        return @{
            encoding = "utf-8"
            overwrite = $true
            createLogs = $true
            checkUpdates = $true
            outputFolder = "output"
            inputFolder = "input"
            openAfterConvert = $false
            showExecutionTime = $true
        }
    }

    return Get-Content -Raw -Encoding UTF8 $ConfigPath | ConvertFrom-Json
}

function Find-SystemPython {
    $commands = @(
        @{ File = "py"; Args = @("-3") },
        @{ File = "python"; Args = @() }
    )

    foreach ($command in $commands) {
        try {
            & $command.File @($command.Args + @("--version")) *> $null
            if ($LASTEXITCODE -eq 0) {
                return $command
            }
        }
        catch {
        }
    }

    Fail "No se encontro Python 3.11+. Instala Python y agregalo al PATH."
}

function Invoke-SystemPython {
    param(
        [hashtable]$PythonCommand,
        [string[]]$Arguments
    )

    & $PythonCommand.File @($PythonCommand.Args + $Arguments)
    if ($LASTEXITCODE -ne 0) {
        Fail "Fallo el comando Python: $($Arguments -join ' ')"
    }
}

function Ensure-Venv {
    param([hashtable]$PythonCommand)

    if (Test-Path $VenvPython) {
        Write-Ok "Entorno virtual encontrado."
        return
    }

    Write-Info "Creando entorno virtual en .venv..."
    Invoke-SystemPython -PythonCommand $PythonCommand -Arguments @("-m", "venv", $VenvDir)

    if (-not (Test-Path $VenvPython)) {
        Fail "No se pudo crear el entorno virtual."
    }

    Write-Ok "Entorno virtual creado."
}

function Invoke-VenvPython {
    param([string[]]$Arguments)

    & $VenvPython @Arguments
}

function Ensure-Pip {
    Write-Info "Actualizando pip..."
    Invoke-VenvPython -Arguments @("-m", "pip", "install", "--upgrade", "pip")
    if ($LASTEXITCODE -ne 0) {
        Fail "No se pudo actualizar pip."
    }
}

function Get-InstalledMarkItDownVersion {
    $script = @"
import importlib.metadata as m
try:
    print(m.version('markitdown'))
except m.PackageNotFoundError:
    pass
"@
    $version = & $VenvPython -c $script
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($version)) {
        return $null
    }

    return ($version | Select-Object -First 1).Trim()
}

function Ensure-MarkItDown {
    $installed = Get-InstalledMarkItDownVersion
    if ($installed) {
        Write-Ok "MarkItDown instalado: $installed"
        return
    }

    Write-Info "Instalando markitdown[all]..."
    Invoke-VenvPython -Arguments @("-m", "pip", "install", "markitdown[all]")
    if ($LASTEXITCODE -ne 0) {
        Fail "No se pudo instalar markitdown[all]."
    }
}

function Get-VenvPythonMinorVersion {
    $minor = & $VenvPython -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
    if ($LASTEXITCODE -eq 0) {
        try {
            return [version]$minor
        }
        catch {
        }
    }

    return $null
}

function Warn-IfPythonIsTooNew {
    $minor = Get-VenvPythonMinorVersion
    if ($minor -and $minor -ge [version]"3.14") {
        Write-Warn "Estas usando Python $minor. Si pip instala una version antigua de MarkItDown, instala Python 3.11, 3.12 o 3.13 y recrea .venv."
    }
}

function Get-AvailableMarkItDownVersion {
    $index = & $VenvPython -m pip index versions markitdown 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    foreach ($line in $index) {
        if ($line -match "^markitdown\s+\(([^)]+)\)") {
            return $Matches[1].Trim()
        }
        if ($line -match "^Available versions:\s*(.+)$") {
            return ($Matches[1].Split(",")[0]).Trim()
        }
    }

    return $null
}

function Update-MarkItDownIfNeeded {
    param($Config)

    if (-not $Config.checkUpdates) {
        return
    }

    $installed = Get-InstalledMarkItDownVersion
    $available = Get-AvailableMarkItDownVersion

    if (-not $installed -or -not $available) {
        Write-Warn "No se pudo consultar la version disponible de MarkItDown."
        return
    }

    try {
        if ([version]$available -le [version]$installed) {
            Write-Ok "MarkItDown esta actualizado."
            return
        }
    }
    catch {
        if ($available -eq $installed) {
            return
        }
    }

    Write-Warn "Existe una nueva version de MarkItDown."
    Write-Host ""
    Write-Host "Version instalada: $installed"
    Write-Host "Version disponible: $available"
    Write-Host ""

    $pythonMinor = Get-VenvPythonMinorVersion
    if ($pythonMinor -and $pythonMinor -ge [version]"3.14") {
        Write-Warn "Se omite la actualizacion automatica porque Python $pythonMinor esta resolviendo MarkItDown a una version antigua. Instala Python 3.11, 3.12 o 3.13 y recrea .venv para actualizar."
        return
    }

    $shouldUpdate = $Silent
    if (-not $Silent) {
        $answer = Read-Host "Desea actualizar? (S/N)"
        $shouldUpdate = $answer -match "^[sS]"
    }

    if ($shouldUpdate) {
        Write-Info "Actualizando MarkItDown..."
        Invoke-VenvPython -Arguments @("-m", "pip", "install", "--upgrade", "markitdown[all]")
        if ($LASTEXITCODE -ne 0) {
            Fail "No se pudo actualizar MarkItDown."
        }
    }
}

function Resolve-SourcePath {
    param(
        [string]$Value,
        $Config
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        if ($Silent) {
            Fail "Debes indicar -Source cuando usas -Silent."
        }
        $Value = Read-Host "Ruta del archivo a convertir"
    }

    if ([System.IO.Path]::IsPathRooted($Value)) {
        return [System.IO.Path]::GetFullPath($Value)
    }

    $direct = Join-Path $ProjectRoot $Value
    if (Test-Path $direct) {
        return [System.IO.Path]::GetFullPath($direct)
    }

    $fromInput = Join-Path (Join-Path $ProjectRoot $Config.inputFolder) $Value
    return [System.IO.Path]::GetFullPath($fromInput)
}

function Resolve-OutputPath {
    param(
        [string]$SourcePath,
        [string]$Value,
        $Config
    )

    if (-not [string]::IsNullOrWhiteSpace($Value)) {
        if ([System.IO.Path]::IsPathRooted($Value)) {
            return [System.IO.Path]::GetFullPath($Value)
        }
        return [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $Value))
    }

    $name = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath) + ".md"
    return [System.IO.Path]::GetFullPath((Join-Path (Join-Path $ProjectRoot $Config.outputFolder) $name))
}

function Show-Diagnostics {
    param($Config)

    Write-Host "Proyecto: $ProjectRoot"
    Write-Host "VENV: $VenvDir"
    Write-Host "Python VENV: $VenvPython"
    Write-Host "Config: $ConfigPath"
    Write-Host "Encoding consola: $([Console]::OutputEncoding.WebName)"

    if (Test-Path $VenvPython) {
        & $VenvPython --version
        & $VenvPython -m pip --version
        $version = Get-InstalledMarkItDownVersion
        if ($version) {
            Write-Host "MarkItDown: $version"
        }
        else {
            Write-Host "MarkItDown: no instalado"
        }
    }
    else {
        Write-Host "Python VENV: no disponible"
    }

    Write-Host "Configuracion:"
    $Config | ConvertTo-Json -Depth 5
}

$started = Get-Date
$config = Load-Config
$pythonCommand = Find-SystemPython

Ensure-Venv -PythonCommand $pythonCommand
Warn-IfPythonIsTooNew
Ensure-Pip
Ensure-MarkItDown

if ($Diagnose) {
    Show-Diagnostics -Config $config
    exit 0
}

Update-MarkItDownIfNeeded -Config $config

$sourcePath = Resolve-SourcePath -Value $Source -Config $config
if (-not (Test-Path $sourcePath)) {
    Fail "No existe el archivo origen: $sourcePath"
}

$outputPath = Resolve-OutputPath -SourcePath $sourcePath -Value $Output -Config $config
$outputDir = Split-Path -Parent $outputPath
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$canOverwrite = $Overwrite -or $config.overwrite
if ((Test-Path $outputPath) -and -not $canOverwrite) {
    if ($Silent) {
        Fail "El archivo destino ya existe y la sobrescritura esta desactivada: $outputPath"
    }

    $answer = Read-Host "El archivo ya existe. Desea reemplazarlo? (S/N)"
    if ($answer -notmatch "^[sS]") {
        Write-Warn "Conversion cancelada por el usuario."
        exit 0
    }
}

Write-Info "Convirtiendo archivo..."
& $VenvPython $ConverterPath --source $sourcePath --output $outputPath --config $ConfigPath
if ($LASTEXITCODE -ne 0) {
    Fail "La conversion fallo."
}

$elapsed = (Get-Date) - $started
Write-Ok "Conversion realizada."
Write-Host "Origen: $sourcePath"
Write-Host "Destino: $outputPath"

if ($config.showExecutionTime) {
    Write-Host ("Tiempo: {0:N2}s" -f $elapsed.TotalSeconds)
}

if ($Open -or $config.openAfterConvert) {
    $codeCommand = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCommand) {
        & code $outputPath
    }
    else {
        Write-Warn "No se encontro VS Code en PATH para abrir el archivo."
    }
}
