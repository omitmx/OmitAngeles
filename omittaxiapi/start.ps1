# 🚀 Script para Iniciar Angeles API Server
Write-Host ""
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    🏍️  ANGELES MOTOTAXI API SERVER  🏍️     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Verificar MongoDB
Write-Host "🔍 Verificando MongoDB..." -ForegroundColor Yellow
$mongoService = Get-Service -Name "MongoDB" -ErrorAction SilentlyContinue

if ($mongoService) {
    if ($mongoService.Status -eq "Running") {
        Write-Host "✅ MongoDB corriendo" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Iniciando MongoDB..." -ForegroundColor Yellow
        Start-Service -Name "MongoDB"
        Start-Sleep -Seconds 2
        Write-Host "✅ MongoDB iniciado" -ForegroundColor Green
    }
} else {
    Write-Host "❌ MongoDB no instalado" -ForegroundColor Red
    Write-Host "   Descarga: https://www.mongodb.com/try/download/community" -ForegroundColor Cyan
    Write-Host ""
    pause
    exit
}

# Mostrar IP
Write-Host ""
Write-Host "📍 Tu IP local:" -ForegroundColor Cyan
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "10.*" -or $_.IPAddress -like "192.168.*"}).IPAddress
Write-Host "   $ipAddress" -ForegroundColor Green

# URLs
Write-Host ""
Write-Host "📡 El API estará disponible en:" -ForegroundColor Cyan
Write-Host "   API REST:  http://${ipAddress}:3000/api" -ForegroundColor White
Write-Host "   WebSocket: http://${ipAddress}:3000" -ForegroundColor White
Write-Host ""

# Iniciar servidor
Write-Host "🚀 Iniciando servidor..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Presiona Ctrl+C para detener el servidor" -ForegroundColor Gray
Write-Host ""

# Cambiar al directorio del API
Set-Location "c:\MX\OmitTaxi\omittaxiapi"

# Ejecutar npm start
npm start
