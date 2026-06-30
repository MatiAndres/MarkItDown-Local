# Ejemplos

Convertir solicitando archivo por consola:

```powershell
.\MarkItDown.ps1
```

Convertir un documento especifico:

```powershell
.\MarkItDown.ps1 -Source .\input\Manual.docx
```

Convertir un PDF a una ruta concreta:

```powershell
.\MarkItDown.ps1 -Source .\input\Arquitectura.pdf -Output .\output\arquitectura.md
```

Sobrescribir sin preguntar:

```powershell
.\MarkItDown.ps1 -Source .\input\API.xlsx -Overwrite -Silent
```

Mostrar diagnostico:

```powershell
.\MarkItDown.ps1 -Diagnose
```

