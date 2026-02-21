# Script para abrir el firewall (ejecutar como Administrador)

Write-Host "🔥 Configurando Firewall de Windows..." -ForegroundColor Cyan

# Eliminar regla anterior si existe
Remove-NetFirewallRule -DisplayName "Node.js Server Port 3000" -ErrorAction SilentlyContinue

# Crear nueva regla
New-NetFirewallRule -DisplayName "Node.js Server Port 3000" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 3000 `
    -Action Allow `
    -Profile Any `
    -Enabled True

Write-Host "✅ Firewall configurado correctamente!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Tu API está disponible en:" -ForegroundColor Yellow
Write-Host "   http://192.168.50.126:3000" -ForegroundColor White
Write-Host ""
Write-Host "📱 Prueba desde tu celular abriendo en el navegador:" -ForegroundColor Yellow
Write-Host "   http://192.168.50.126:3000" -ForegroundColor White

pause
