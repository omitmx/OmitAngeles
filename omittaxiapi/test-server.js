// Test server simple para verificar conectividad
const http = require('http');

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Servidor funcionando correctamente!\n');
});

const PORT = 3000;
const HOST = '0.0.0.0';

server.listen(PORT, HOST, () => {
  console.log(`Servidor de prueba corriendo en:`);
  console.log(`  - http://localhost:${PORT}`);
  console.log(`  - http://10.1.7.106:${PORT}`);
  console.log(`\nPresiona Ctrl+C para detener`);
});
