const mongoose = require('mongoose');
const User = require('./models/User');
const Ride = require('./models/Ride');
require('dotenv').config();

const seedDatabase = async () => {
  try {
    // Conectar a MongoDB
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('✅ Conectado a MongoDB');

    // Limpiar colecciones existentes
    await User.deleteMany({});
    await Ride.deleteMany({});
    console.log('🗑️  Base de datos limpiada');

    // Crear usuarios de prueba - Pasajeros
    const passengers = await User.create([
      {
        name: 'Ana García',
        email: 'ana@test.com',
        phone: '+525512345001',
        password: 'password123',
        userType: 'passenger',
        rating: 4.8,
        totalRides: 15
      },
      {
        name: 'Luis Martínez',
        email: 'luis@test.com',
        phone: '+525512345002',
        password: 'password123',
        userType: 'passenger',
        rating: 4.9,
        totalRides: 23
      },
      {
        name: 'María Rodríguez',
        email: 'maria@test.com',
        phone: '+525512345003',
        password: 'password123',
        userType: 'passenger',
        rating: 5.0,
        totalRides: 8
      }
    ]);
    console.log('✅ Pasajeros creados:', passengers.length);

    // Crear usuarios de prueba - Conductores
    const drivers = await User.create([
      {
        name: 'Carlos Conductor',
        email: 'carlos@test.com',
        phone: '+525587654001',
        password: 'password123',
        userType: 'driver',
        rating: 4.9,
        totalRides: 156,
        licenseNumber: 'LIC123456',
        vehicleInfo: {
          brand: 'Honda',
          model: 'Wave',
          year: 2022,
          plate: 'ABC-123',
          color: 'Rojo'
        },
        isOnline: true,
        currentLocation: {
          type: 'Point',
          coordinates: [-99.1332, 19.4326] // CDMX Centro
        }
      },
      {
        name: 'Roberto Ramírez',
        email: 'roberto@test.com',
        phone: '+525587654002',
        password: 'password123',
        userType: 'driver',
        rating: 4.7,
        totalRides: 89,
        licenseNumber: 'LIC789012',
        vehicleInfo: {
          brand: 'Yamaha',
          model: 'Crypton',
          year: 2021,
          plate: 'XYZ-456',
          color: 'Azul'
        },
        isOnline: true,
        currentLocation: {
          type: 'Point',
          coordinates: [-99.1450, 19.4420] // Cerca del centro
        }
      },
      {
        name: 'Miguel Ángel López',
        email: 'miguel@test.com',
        phone: '+525587654003',
        password: 'password123',
        userType: 'driver',
        rating: 5.0,
        totalRides: 234,
        licenseNumber: 'LIC345678',
        vehicleInfo: {
          brand: 'Italika',
          model: 'AT125',
          year: 2023,
          plate: 'DEF-789',
          color: 'Negro'
        },
        isOnline: false,
        currentLocation: {
          type: 'Point',
          coordinates: [-99.1280, 19.4280]
        }
      }
    ]);
    console.log('✅ Conductores creados:', drivers.length);

    // Crear viajes de ejemplo
    const rides = await Ride.create([
      {
        passenger: passengers[0]._id,
        driver: drivers[0]._id,
        pickupLocation: {
          address: 'Av. Reforma 123, CDMX',
          coordinates: {
            type: 'Point',
            coordinates: [-99.1332, 19.4326]
          }
        },
        dropoffLocation: {
          address: 'Polanco, CDMX',
          coordinates: {
            type: 'Point',
            coordinates: [-99.1900, 19.4400]
          }
        },
        distance: 4.2,
        estimatedDuration: 12,
        fare: {
          baseFare: 20,
          distanceFare: 33.6,
          total: 53.6
        },
        status: 'completed',
        paymentStatus: 'completed',
        passengerRating: 5,
        driverRating: 5,
        requestedAt: new Date('2024-02-10T08:30:00'),
        acceptedAt: new Date('2024-02-10T08:31:00'),
        startedAt: new Date('2024-02-10T08:35:00'),
        completedAt: new Date('2024-02-10T08:47:00')
      },
      {
        passenger: passengers[1]._id,
        driver: drivers[1]._id,
        pickupLocation: {
          address: 'Condesa, CDMX',
          coordinates: {
            type: 'Point',
            coordinates: [-99.1700, 19.4100]
          }
        },
        dropoffLocation: {
          address: 'Roma Norte, CDMX',
          coordinates: {
            type: 'Point',
            coordinates: [-99.1600, 19.4200]
          }
        },
        distance: 2.5,
        estimatedDuration: 8,
        fare: {
          baseFare: 20,
          distanceFare: 20,
          total: 40
        },
        status: 'completed',
        paymentStatus: 'completed',
        passengerRating: 4,
        driverRating: 5,
        requestedAt: new Date('2024-02-10T14:15:00'),
        acceptedAt: new Date('2024-02-10T14:16:00'),
        startedAt: new Date('2024-02-10T14:20:00'),
        completedAt: new Date('2024-02-10T14:28:00')
      },
      {
        passenger: passengers[0]._id,
        driver: null,
        pickupLocation: {
          address: 'Centro Histórico, CDMX',
          coordinates: {
            type: 'Point',
            coordinates: [-99.1332, 19.4326]
          }
        },
        dropoffLocation: {
          address: 'Coyoacán, CDMX',
          coordinates: {
            type: 'Point',
            coordinates: [-99.1620, 19.3500]
          }
        },
        distance: 8.5,
        estimatedDuration: 25,
        fare: {
          baseFare: 20,
          distanceFare: 68,
          total: 88
        },
        status: 'requested',
        paymentStatus: 'pending',
        requestedAt: new Date()
      }
    ]);
    console.log('✅ Viajes creados:', rides.length);

    console.log('\n🎉 Base de datos poblada exitosamente!');
    console.log('\n📋 Credenciales de prueba:');
    console.log('\n--- PASAJEROS ---');
    console.log('Email: ana@test.com | Password: password123');
    console.log('Email: luis@test.com | Password: password123');
    console.log('Email: maria@test.com | Password: password123');
    console.log('\n--- CONDUCTORES ---');
    console.log('Email: carlos@test.com | Password: password123');
    console.log('Email: roberto@test.com | Password: password123');
    console.log('Email: miguel@test.com | Password: password123');

    mongoose.connection.close();
    console.log('\n✅ Conexión cerrada');
  } catch (error) {
    console.error('❌ Error al poblar la base de datos:', error);
    process.exit(1);
  }
};

seedDatabase();
