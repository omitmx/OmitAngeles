const mongoose = require('mongoose');
const Ride = require('./models/Ride');

mongoose.connect('mongodb://localhost:27017/angeles_mototaxi').then(async () => {
  console.log('Conectado a MongoDB\n');
  
  // Buscar viajes activos del pasajero
  const passengerId = '6993c512145f010d0fd8aca7';
  const activeRides = await Ride.find({ 
    passenger: passengerId, 
    status: { $in: ['requested', 'accepted', 'arrived', 'in_progress'] } 
  });
  
  console.log(`Viajes activos para pasajero ${passengerId}: ${activeRides.length}`);
  activeRides.forEach(r => {
    console.log(`  - ID: ${r._id} | Estado: ${r.status} | Fecha: ${r.createdAt}`);
  });
  
  // Mostrar todos los viajes del pasajero (últimos 10)
  console.log(`\nTodos los viajes del pasajero (últimos 10):`);
  const allRides = await Ride.find({ passenger: passengerId })
    .sort({ createdAt: -1 })
    .limit(10);
  
  allRides.forEach(r => {
    console.log(`  - ID: ${r._id} | Estado: ${r.status} | Fecha: ${r.createdAt}`);
  });
  
  process.exit(0);
});
