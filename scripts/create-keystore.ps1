# Script para crear `keystore.properties` desde la plantilla
# Uso: ejecutar desde la raíz del proyecto (entredos)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$template = Join-Path -Path $root -ChildPath "android\keystore.properties.template"
$dest = Join-Path -Path $root -ChildPath "keystore.properties"

if (!(Test-Path $template)) {
    Write-Error "Plantilla no encontrada: $template"
    exit 1
}

if (Test-Path $dest) {
    Write-Host "El archivo 'keystore.properties' ya existe en la raíz del proyecto: $dest"
    $overwrite = Read-Host "¿Deseas sobrescribirlo? (S/N)"
    if ($overwrite -ne 'S' -and $overwrite -ne 's') {
        Write-Host "Abortando. No se hicieron cambios."
        exit 0
    }
}

Write-Host "Creando 'keystore.properties' a partir de la plantilla..."
Copy-Item -Path $template -Destination $dest -Force

# Leer valores del usuario
$storeFile = Read-Host "Ruta completa al keystore (.jks) [ej: C:\keys\my-release.jks]"
$storePassword = Read-Host "Password del keystore" -AsSecureString
$keyAlias = Read-Host "Alias de la clave (keyAlias) [ej: upload]"
$keyPassword = Read-Host "Password de la clave (keyPassword)" -AsSecureString

# Convertir SecureString a texto (local only) — NO recomendado para compartir
function ConvertFrom-SecureStringToPlainText($secureString) {
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    try { [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) } finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

$storePasswordPlain = ConvertFrom-SecureStringToPlainText $storePassword
$keyPasswordPlain = ConvertFrom-SecureStringToPlainText $keyPassword

# Escribir el archivo keystore.properties con las entradas
@"
storeFile=$storeFile
storePassword=$storePasswordPlain
keyAlias=$keyAlias
keyPassword=$keyPasswordPlain
"@ | Out-File -FilePath $dest -Encoding UTF8 -Force

Write-Host "Archivo 'keystore.properties' creado en: $dest"
Write-Host "IMPORTANTE: No subas este archivo al repositorio. Está incluido en .gitignore por seguridad."
