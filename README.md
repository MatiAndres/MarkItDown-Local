# MarkItDown Local Launcher

Utilidad local para convertir documentos a Markdown usando Microsoft MarkItDown sin tener que activar entornos virtuales, instalar dependencias manualmente ni recordar comandos de Python.

El flujo esperado es ejecutar un archivo `.ps1`, apuntar a un documento dentro de `input/` o a una ruta absoluta, y obtener el `.md` generado en `output/`.

## Requisitos

- Windows con PowerShell.
- Python 3.11 o superior disponible como `python` o `py`.
- Recomendado: Python 3.11, 3.12 o 3.13 para obtener las versiones recientes de MarkItDown. Con Python 3.14, `pip` puede resolver una version antigua por compatibilidad de dependencias.
- Conexion a internet para la primera instalacion y para consultar actualizaciones.

## Uso rapido

Desde la raiz del proyecto:

```powershell
.\MarkItDown.ps1
```

El launcher verifica Python, crea `.venv` si no existe, actualiza `pip`, instala `markitdown[all]` si falta, consulta nuevas versiones y luego solicita el archivo a convertir.

Tambien puedes indicar el archivo directamente:

```powershell
.\MarkItDown.ps1 -Source .\input\Manual.docx
```

Guardar en una ruta especifica:

```powershell
.\MarkItDown.ps1 -Source .\input\Manual.docx -Output .\output\Manual.md
```

Abrir el Markdown generado en VS Code:

```powershell
.\MarkItDown.ps1 -Source .\input\Manual.docx -Open
```

Ejecutar diagnostico:

```powershell
.\MarkItDown.ps1 -Diagnose
```

## Parametros

- `-Source`: archivo origen. Si se omite, el launcher pregunta por consola.
- `-Output`: archivo Markdown destino. Si se omite, se crea en `output/` con extension `.md`.
- `-Open`: abre el resultado en VS Code si `code` esta disponible.
- `-Overwrite`: sobrescribe sin preguntar.
- `-Silent`: evita preguntas y usa la configuracion.
- `-Diagnose`: muestra Python, pip, MarkItDown, venv, rutas y encoding.

## Configuracion

La configuracion vive en [config/config.json](config/config.json):

```json
{
  "encoding": "utf-8",
  "overwrite": true,
  "createLogs": true,
  "checkUpdates": true,
  "outputFolder": "output",
  "inputFolder": "input",
  "openAfterConvert": false,
  "showExecutionTime": true
}
```

## Formatos soportados

El proyecto no limita extensiones. Acepta los formatos soportados por la version instalada de Microsoft MarkItDown: PDF, DOCX, PPTX, XLSX, CSV, JSON, XML, HTML, ZIP, imagenes, audio y futuros formatos compatibles.

## Estructura

```text
MarkItDown-Local/
├── MarkItDown.ps1
├── scripts/
│   ├── MarkItDown.ps1
│   └── instalar.ps1
├── src/
│   ├── convertir_markitdown.py
│   ├── config.py
│   ├── utils.py
│   └── version.py
├── config/
│   └── config.json
├── input/
├── output/
├── logs/
├── docs/
└── tests/
```

## Solucion de problemas

Si PowerShell bloquea la ejecucion de scripts, ejecuta desde una consola permitida:

```powershell
powershell -ExecutionPolicy Bypass -File .\MarkItDown.ps1
```

Si Python no se detecta, instala Python 3.11+ y marca la opcion de agregarlo al PATH.

Si falla la instalacion de MarkItDown, revisa conexion a internet y ejecuta:

```powershell
.\MarkItDown.ps1 -Diagnose
```

## Actualizacion

En cada ejecucion, si `checkUpdates` esta activo, el launcher consulta PyPI con `pip index versions markitdown`. Si hay una version mas nueva, pregunta si deseas actualizar.
