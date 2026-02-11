# Script para configurar Firewall de Windows para Angeles API
# Ejecutar como Administrador

Write-Host "🔥 Configurando Firewall para Angeles API..." -ForegroundColor Cyan

# Verificar si se ejecuta como administrador
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ ERROR: Este script debe ejecutarse como Administrador" -ForegroundColor Red
    Write-Host ""
    Write-Host "Pasos:" -ForegroundColor Yellow
    Write-Host "1. Cierra esta ventana" -ForegroundColor White
    Write-Host "2. Click derecho en PowerShell" -ForegroundColor White
    Write-Host "3. Selecciona 'Ejecutar como Administrador'" -ForegroundColor White
    Write-Host "4. Ejecuta este script nuevamente" -ForegroundColor White
    Write-Host ""
    pause
    exit
}

# Crear regla de firewall para puerto 3000
try {
    # Verificar si la regla ya existe
    $existingRule = Get-NetFirewallRule -DisplayName "Angeles API" -ErrorAction SilentlyContinue
    
    if ($existingRule) {
        Write-Host "⚠️  La regla 'Angeles API' ya existe. Eliminando..." -ForegroundColor Yellow
        Remove-NetFirewallRule -DisplayName "Angeles API"
    }
    
    # Crear nueva regla
    New-NetFirewallRule -DisplayName "Angeles API" `
                        -Direction Inbound `
                        -LocalPort 3000 `
                        -Protocol TCP `
                        -Action Allow `
                        -Profile Any `
                        -Description "Permite conexiones al servidor Angeles Mototaxi API en puerto 3000"
    
    Write-Host "✅ Regla de firewall creada exitosamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "Detalles de la regla:" -ForegroundColor Cyan
    Write-Host "  - Nombre: Angeles API" -ForegroundColor White
    Write-Host "  - Puerto: 3000" -ForegroundColor White
    Write-Host "  - Protocolo: TCP" -ForegroundColor White
    Write-Host "  - Dirección: Entrada" -ForegroundColor White
    Write-Host "  - Acción: Permitir" -ForegroundColor White
    Write-Host ""
    
    # Mostrar IP local
    Write-Host "📍 Tu IP local actual:" -ForegroundColor Cyan
    $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "10.*" -or $_.IPAddress -like "192.168.*"}).IPAddress
    if ($ipAddress) {
        Write-Host "  $ipAddress" -ForegroundColor Green
        Write-Host ""
        Write-Host "✅ Usa esta IP en tu app Flutter: http://${ipAddress}:3000/api" -ForegroundColor Yellow
    } else {
        Write-Host "  No se encontró IP de red local" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "🎉 Configuración completada!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Siguiente paso: Iniciar el servidor API" -ForegroundColor Cyan
    Write-Host "  cd c:\MX\OmitTaxi\omittaxiapi" -ForegroundColor White
    Write-Host "  npm start" -ForegroundColor White
    
} catch {
    Write-Host "❌ Error al crear regla de firewall: $_" -ForegroundColor Red
}

Write-Host ""
pause
