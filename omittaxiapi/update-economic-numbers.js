const mongoose = require('mongoose');
require('dotenv').config();
const User = require('./models/User');

// Conectar a MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/omittaxi', {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log('✅ Conectado a MongoDB'))
.catch(err => {
  console.error('❌ Error al conectar a MongoDB:', err);
  process.exit(1);
});

async function updateDrivers() {
  try {
    // Obtener todos los conductores
    const drivers = await User.find({ userType: 'driver' });
    
    console.log(`\n📋 Encontrados ${drivers.length} conductores\n`);
    
    let counter = 1;
    for (const driver of drivers) {
      // Si el conductor ya tiene número económico, no lo actualizamos
      if (driver.economicNumber) {
        console.log(`✓ ${driver.name} ya tiene número económico: #${driver.economicNumber}`);
        continue;
      }
      
      // Asignar número económico secuencial
      driver.economicNumber = counter.toString().padStart(2, '0');
      await driver.save();
      
      console.log(`✅ ${driver.name} - Asignado número económico: #${driver.economicNumber}`);
      counter++;
    }
    
    console.log(`\n✅ Actualización completada. ${counter - 1} conductores actualizados.\n`);
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

updateDrivers();
