const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const User = require('../models/User');
const Ride = require('../models/Ride');

// Store de ubicaciones de conductores en memoria (en producción usar Redis o MongoDB)
const driverLocations = new Map();

/**
 * @route   POST /api/location/update
 * @desc    Actualizar ubicación del conductor
 * @access  Private (Driver)
 */
router.post('/update', protect, async (req, res) => {
  try {
    const { lat, lng } = req.body;
    const userId = req.user.userId;

    if (!lat || !lng) {
      return res.status(400).json({ error: 'Latitud y longitud requeridas' });
    }

    // Guardar ubicación del conductor
    driverLocations.set(userId, {
      lat: parseFloat(lat),
      lng: parseFloat(lng),
      timestamp: new Date(),
      userId
    });

    console.log(`📍 Ubicación actualizada para conductor ${userId}: ${lat}, ${lng}`);

    // Si el conductor tiene un viaje activo, emitir la ubicación al pasajero
    const activeRide = await Ride.findOne({
      driver: userId,
      status: { $in: ['accepted', 'arrived'] }
    }).populate('passenger', 'name');

    if (activeRide) {
      const io = req.app.get('io');
      io.emit('driver:location', {
        rideId: activeRide._id,
        driverId: userId,
        passengerId: activeRide.passenger._id,
        location: { lat: parseFloat(lat), lng: parseFloat(lng) }
      });
      console.log(`📡 Ubicación enviada al pasajero ${activeRide.passenger.name} para viaje ${activeRide._id}`);
    }

    res.json({
      success: true,
      message: 'Ubicación actualizada',
      location: { lat, lng }
    });
  } catch (error) {
    console.error('Error al actualizar ubicación:', error);
    res.status(500).json({ error: 'Error al actualizar ubicación' });
  }
});

/**
 * @route   GET /api/location/nearby-drivers
 * @desc    Obtener conductores cercanos
 * @access  Private
 */
router.get('/nearby-drivers', protect, async (req, res) => {
  try {
    const { lat, lng, radius = 5000 } = req.query; // radius en metros

    if (!lat || !lng) {
      return res.status(400).json({ error: 'Latitud y longitud requeridas' });
    }

    const userLat = parseFloat(lat);
    const userLng = parseFloat(lng);
    const searchRadius = parseFloat(radius);

    // Filtrar conductores cercanos
    const nearbyDrivers = [];
    const now = new Date();

    for (const [driverId, location] of driverLocations.entries()) {
      // Verificar que la ubicación sea reciente (últimos 5 minutos)
      const timeDiff = now - location.timestamp;
      if (timeDiff > 5 * 60 * 1000) continue; // Skip ubicaciones antiguas

      const distance = calculateDistance(
        userLat,
        userLng,
        location.lat,
        location.lng
      );

      if (distance <= searchRadius) {
        nearbyDrivers.push({
          driverId,
          location: {
            lat: location.lat,
            lng: location.lng
          },
          distance: Math.round(distance),
          lastUpdate: location.timestamp
        });
      }
    }

    // Ordenar por distancia
    nearbyDrivers.sort((a, b) => a.distance - b.distance);

    // Obtener datos de los conductores desde MongoDB
    const driverIds = nearbyDrivers.map(d => d.driverId);
    const drivers = await User.find({ _id: { $in: driverIds } })
      .select('name phone rating vehicleInfo');

    // Combinar datos de ubicación con datos del conductor
    const driversWithInfo = nearbyDrivers.map(nearby => {
      const driverData = drivers.find(d => d._id.toString() === nearby.driverId);
      return {
        ...nearby,
        name: driverData?.name || 'Conductor',
        phone: driverData?.phone,
        rating: driverData?.rating || 0,
        vehicleInfo: driverData?.vehicleInfo
      };
    });

    console.log(`📡 Encontrados ${driversWithInfo.length} conductores cercanos`);

    res.json({
      success: true,
      count: driversWithInfo.length,
      drivers: driversWithInfo.slice(0, 10) // Máximo 10 conductores
    });
  } catch (error) {
    console.error('Error al buscar conductores cercanos:', error);
    res.status(500).json({ error: 'Error al buscar conductores' });
  }
});

/**
 * @route   GET /api/location/driver/:driverId
 * @desc    Obtener ubicación de un conductor específico
 * @access  Private
 */
router.get('/driver/:driverId', protect, async (req, res) => {
  try {
    const { driverId } = req.params;
    const location = driverLocations.get(driverId);

    if (!location) {
      return res.status(404).json({ error: 'Conductor no encontrado o sin ubicación reciente' });
    }

    res.json({
      success: true,
      location: {
        lat: location.lat,
        lng: location.lng,
        timestamp: location.timestamp
      }
    });
  } catch (error) {
    console.error('Error al obtener ubicación del conductor:', error);
    res.status(500).json({ error: 'Error al obtener ubicación' });
  }
});

/**
 * @route   DELETE /api/location/clear
 * @desc    Limpiar ubicación del conductor (cuando se desconecta)
 * @access  Private (Driver)
 */
router.delete('/clear', protect, async (req, res) => {
  try {
    const userId = req.user.userId;
    driverLocations.delete(userId);

    console.log(`🗑️ Ubicación eliminada para conductor ${userId}`);

    res.json({
      success: true,
      message: 'Ubicación eliminada'
    });
  } catch (error) {
    console.error('Error al eliminar ubicación:', error);
    res.status(500).json({ error: 'Error al eliminar ubicación' });
  }
});

// Función auxiliar para calcular distancia entre dos puntos (Haversine formula)
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Radio de la Tierra en metros
  const φ1 = lat1 * Math.PI / 180;
  const φ2 = lat2 * Math.PI / 180;
  const Δφ = (lat2 - lat1) * Math.PI / 180;
  const Δλ = (lon2 - lon1) * Math.PI / 180;

  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) *
    Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Distancia en metros
}

module.exports = router;
