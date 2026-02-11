const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const http = require('http');
const socketIO = require('socket.io');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Conexión a MongoDB
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ Conectado a MongoDB'))
.catch(err => console.error('❌ Error de conexión a MongoDB:', err));

// Importar rutas
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const rideRoutes = require('./routes/rides');
const driverRoutes = require('./routes/drivers');

// Usar rutas
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/rides', rideRoutes);
app.use('/api/drivers', driverRoutes);

// Ruta de prueba
app.get('/', (req, res) => {
  res.json({ 
    message: '🏍️ Angeles Mototaxi API',
    version: '1.0.0',
    status: 'running'
  });
});

// WebSocket para tracking en tiempo real
const activeDrivers = new Map();
const activeRides = new Map();

io.on('connection', (socket) => {
  console.log('🔌 Cliente conectado:', socket.id);

  // Driver se conecta y comparte ubicación
  socket.on('driver:online', (data) => {
    const { driverId, location } = data;
    activeDrivers.set(driverId, {
      socketId: socket.id,
      location,
      available: true
    });
    console.log(`🏍️ Conductor ${driverId} en línea`);
  });

  // Driver actualiza ubicación
  socket.on('driver:location', (data) => {
    const { driverId, location } = data;
    if (activeDrivers.has(driverId)) {
      activeDrivers.get(driverId).location = location;
      
      // Notificar a pasajeros en viajes activos
      activeRides.forEach((ride, rideId) => {
        if (ride.driverId === driverId) {
          io.to(ride.passengerSocketId).emit('ride:driver-location', {
            rideId,
            location
          });
        }
      });
    }
  });

  // Pasajero solicita viaje
  socket.on('ride:request', (data) => {
    const { rideId, passengerId, pickup, dropoff } = data;
    activeRides.set(rideId, {
      passengerId,
      passengerSocketId: socket.id,
      pickup,
      dropoff,
      status: 'searching'
    });
    
    // Notificar a conductores cercanos
    io.emit('ride:new-request', {
      rideId,
      pickup,
      dropoff
    });
  });

  // Conductor acepta viaje
  socket.on('ride:accept', (data) => {
    const { rideId, driverId } = data;
    if (activeRides.has(rideId)) {
      const ride = activeRides.get(rideId);
      ride.driverId = driverId;
      ride.status = 'accepted';
      
      // Notificar al pasajero
      io.to(ride.passengerSocketId).emit('ride:accepted', {
        rideId,
        driverId,
        driverLocation: activeDrivers.get(driverId)?.location
      });
    }
  });

  // Viaje iniciado
  socket.on('ride:start', (data) => {
    const { rideId } = data;
    if (activeRides.has(rideId)) {
      const ride = activeRides.get(rideId);
      ride.status = 'in_progress';
      io.to(ride.passengerSocketId).emit('ride:started', { rideId });
    }
  });

  // Viaje completado
  socket.on('ride:complete', (data) => {
    const { rideId } = data;
    if (activeRides.has(rideId)) {
      const ride = activeRides.get(rideId);
      ride.status = 'completed';
      io.to(ride.passengerSocketId).emit('ride:completed', { rideId });
      activeRides.delete(rideId);
    }
  });

  // Driver se desconecta
  socket.on('driver:offline', (data) => {
    const { driverId } = data;
    activeDrivers.delete(driverId);
    console.log(`🏍️ Conductor ${driverId} desconectado`);
  });

  socket.on('disconnect', () => {
    console.log('🔌 Cliente desconectado:', socket.id);
    
    // Limpiar conductor si estaba conectado
    for (let [driverId, driver] of activeDrivers.entries()) {
      if (driver.socketId === socket.id) {
        activeDrivers.delete(driverId);
        break;
      }
    }
  });
});

// Puerto del servidor
const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0'; // Escuchar en todas las interfaces de red
server.listen(PORT, HOST, () => {
  console.log(`\n🚀 Servidor corriendo en puerto ${PORT}`);
  console.log(`📡 WebSocket habilitado para tracking en tiempo real`);
  console.log(`🌐 URL Local: http://localhost:${PORT}`);
  console.log(`🌐 URL Red: http://10.1.7.106:${PORT}\n`);
});
