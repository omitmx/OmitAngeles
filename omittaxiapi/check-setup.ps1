# Script para verificar configuración de red y API
Write-Host "🔍 Verificando configuración de Angeles API..." -ForegroundColor Cyan
Write-Host ""

# 1. Verificar IP local
Write-Host "1️⃣  Verificando IP local..." -ForegroundColor Yellow
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "10.*" -or $_.IPAddress -like "192.168.*"}).IPAddress

if ($ipAddress) {
    Write-Host "   ✅ IP Local: $ipAddress" -ForegroundColor Green
    $expectedIP = "10.1.7.106"
    if ($ipAddress -eq $expectedIP) {
        Write-Host "   ✅ IP coincide con la configurada ($expectedIP)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  IP actual ($ipAddress) diferente a la configurada ($expectedIP)" -ForegroundColor Yellow
        Write-Host "   💡 Actualiza lib/config/api_config.dart con la nueva IP" -ForegroundColor Cyan
    }
} else {
    Write-Host "   ❌ No se encontró IP de red local" -ForegroundColor Red
}
Write-Host ""

# 2. Verificar MongoDB
Write-Host "2️⃣  Verificando MongoDB..." -ForegroundColor Yellow
$mongoService = Get-Service -Name "MongoDB" -ErrorAction SilentlyContinue
if ($mongoService) {
    if ($mongoService.Status -eq "Running") {
        Write-Host "   ✅ MongoDB está corriendo" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  MongoDB instalado pero no está corriendo" -ForegroundColor Yellow
        Write-Host "   💡 Ejecuta: net start MongoDB" -ForegroundColor Cyan
    }
} else {
    Write-Host "   ❌ MongoDB no está instalado o no se detectó como servicio" -ForegroundColor Red
    Write-Host "   💡 Descarga desde: https://www.mongodb.com/try/download/community" -ForegroundColor Cyan
}
Write-Host ""

# 3. Verificar puerto 3000
Write-Host "3️⃣  Verificando puerto 3000..." -ForegroundColor Yellow
$port3000 = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
if ($port3000) {
    Write-Host "   ✅ Puerto 3000 en uso (API probablemente corriendo)" -ForegroundColor Green
    Write-Host "   PID: $($port3000.OwningProcess)" -ForegroundColor White
} else {
    Write-Host "   ⚠️  Puerto 3000 libre (API no está corriendo)" -ForegroundColor Yellow
    Write-Host "   💡 Inicia el API con: npm start" -ForegroundColor Cyan
}
Write-Host ""

# 4. Verificar regla de firewall
Write-Host "4️⃣  Verificando Firewall..." -ForegroundColor Yellow
$firewallRule = Get-NetFirewallRule -DisplayName "Angeles API" -ErrorAction SilentlyContinue
if ($firewallRule) {
    if ($firewallRule.Enabled -eq $true) {
        Write-Host "   ✅ Regla de firewall activa" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Regla existe pero está deshabilitada" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ❌ Regla de firewall no encontrada" -ForegroundColor Red
    Write-Host "   💡 Ejecuta setup-firewall.ps1 como Administrador" -ForegroundColor Cyan
}
Write-Host ""

# 5. Verificar Node.js
Write-Host "5️⃣  Verificando Node.js..." -ForegroundColor Yellow
$nodeVersion = node --version 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Node.js instalado: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "   ❌ Node.js no encontrado" -ForegroundColor Red
}
Write-Host ""

# 6. Verificar dependencias de npm
Write-Host "6️⃣  Verificando dependencias npm..." -ForegroundColor Yellow
if (Test-Path "c:\MX\OmitTaxi\omittaxiapi\node_modules") {
    Write-Host "   ✅ Dependencias instaladas" -ForegroundColor Green
} else {
    Write-Host "   ❌ Dependencias no instaladas" -ForegroundColor Red
    Write-Host "   💡 Ejecuta: npm install" -ForegroundColor Cyan
}
Write-Host ""

# Resumen
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "📋 RESUMEN" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

if ($ipAddress) {
    Write-Host ""
    Write-Host "📡 URLs de conexión:" -ForegroundColor Yellow
    Write-Host "   API REST:  http://${ipAddress}:3000/api" -ForegroundColor White
    Write-Host "   WebSocket: http://${ipAddress}:3000" -ForegroundColor White
    Write-Host "   Health:    http://${ipAddress}:3000" -ForegroundColor White
}

Write-Host ""
Write-Host "📝 Pasos siguientes:" -ForegroundColor Yellow

$step = 1
if (-not $mongoService -or $mongoService.Status -ne "Running") {
    Write-Host "   $step. Iniciar MongoDB: net start MongoDB" -ForegroundColor White
    $step++
}

if (-not $firewallRule) {
    Write-Host "   $step. Configurar firewall: setup-firewall.ps1 (como Admin)" -ForegroundColor White
    $step++
}

if (-not $port3000) {
    Write-Host "   $step. Iniciar API: cd c:\MX\OmitTaxi\omittaxiapi && npm start" -ForegroundColor White
    $step++
}

if ($step -eq 1) {
    Write-Host "   ✅ Todo configurado! Puedes ejecutar la app Flutter" -ForegroundColor Green
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""
pause
