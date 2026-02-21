const mongoose = require('mongoose');
const Ride = require('./models/Ride');

mongoose.connect('mongodb://localhost:27017/angeles_mototaxi').then(async () => {
  console.log('Verificando viaje 699688d9088740cd5f36b660...\n');
  
  const ride = await Ride.findById('699688d9088740cd5f36b660');
  if (ride) {
    console.log('Estado del viaje:', ride.status);
    console.log('Pasajero ID:', ride.passenger);
    console.log('Fecha creación:', ride.createdAt);
  } else {
    console.log('Viaje no encontrado');
  }
  
  // Verificar si aparece en búsqueda de activos
  const activeCheck = await Ride.findOne({ 
    _id: '699688d9088740cd5f36b660', 
    status: { $in: ['requested', 'accepted', 'arrived', 'in_progress'] } 
  });
  
  console.log('\n¿Se encuentra en query de viajes activos?', activeCheck ? 'SÍ ❌' : 'NO ✅');
  
  // Buscar otros viajes activos del mismo pasajero
  if (ride) {
    const otherActive = await Ride.find({
      passenger: ride.passenger,
      status: { $in: ['requested', 'accepted', 'arrived', 'in_progress'] }
    });
    
    console.log(`\nOtros viajes activos del pasajero: ${otherActive.length}`);
    otherActive.forEach(r => {
      console.log(`  - ${r._id} | ${r.status}`);
    });
  }
  
  process.exit(0);
});
