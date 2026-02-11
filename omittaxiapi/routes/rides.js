const express = require('express');
const router = express.Router();
const Ride = require('../models/Ride');
const User = require('../models/User');
const { protect, isDriver, isPassenger } = require('../middleware/auth');

// @route   POST /api/rides/request
// @desc    Solicitar un viaje
// @access  Private (Passenger only)
router.post('/request', protect, isPassenger, async (req, res) => {
  try {
    const {
      pickupAddress,
      pickupLat,
      pickupLng,
      dropoffAddress,
      dropoffLat,
      dropoffLng,
      distance,
      estimatedDuration,
      paymentMethod
    } = req.body;

    // Validar datos
    if (!pickupAddress || !pickupLat || !pickupLng || !dropoffAddress || !dropoffLat || !dropoffLng) {
      return res.status(400).json({
        success: false,
        message: 'Faltan datos de ubicación'
      });
    }

    // Crear viaje
    const ride = new Ride({
      passenger: req.user._id,
      pickupLocation: {
        address: pickupAddress,
        coordinates: {
          type: 'Point',
          coordinates: [pickupLng, pickupLat]
        }
      },
      dropoffLocation: {
        address: dropoffAddress,
        coordinates: {
          type: 'Point',
          coordinates: [dropoffLng, dropoffLat]
        }
      },
      distance: distance || 0,
      estimatedDuration: estimatedDuration || 0,
      paymentMethod: paymentMethod || 'cash',
      status: 'requested'
    });

    // Calcular tarifa
    const baseFare = parseFloat(process.env.BASE_FARE) || 20;
    const farePerKm = parseFloat(process.env.FARE_PER_KM) || 8;
    ride.calculateFare(baseFare, farePerKm);

    await ride.save();

    // Poblar datos del pasajero
    await ride.populate('passenger', 'name phone rating');

    res.status(201).json({
      success: true,
      message: 'Viaje solicitado exitosamente',
      data: ride
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al solicitar viaje',
      error: error.message
    });
  }
});

// @route   PUT /api/rides/:id/accept
// @desc    Aceptar un viaje (conductor)
// @access  Private (Driver only)
router.put('/:id/accept', protect, isDriver, async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);

    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Viaje no encontrado'
      });
    }

    if (ride.status !== 'requested') {
      return res.status(400).json({
        success: false,
        message: 'Este viaje ya no está disponible'
      });
    }

    // Actualizar viaje
    ride.driver = req.user._id;
    ride.status = 'accepted';
    ride.acceptedAt = Date.now();
    await ride.save();

    await ride.populate(['passenger', 'driver'], 'name phone rating vehicleInfo');

    res.json({
      success: true,
      message: 'Viaje aceptado',
      data: ride
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al aceptar viaje',
      error: error.message
    });
  }
});

// @route   PUT /api/rides/:id/start
// @desc    Iniciar un viaje
// @access  Private (Driver only)
router.put('/:id/start', protect, isDriver, async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);

    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Viaje no encontrado'
      });
    }

    if (ride.driver.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'No autorizado'
      });
    }

    if (ride.status !== 'accepted' && ride.status !== 'arrived') {
      return res.status(400).json({
        success: false,
        message: 'El viaje debe estar en estado aceptado o llegado'
      });
    }

    ride.status = 'in_progress';
    ride.startedAt = Date.now();
    await ride.save();

    await ride.populate(['passenger', 'driver'], 'name phone rating vehicleInfo');

    res.json({
      success: true,
      message: 'Viaje iniciado',
      data: ride
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al iniciar viaje',
      error: error.message
    });
  }
});

// @route   PUT /api/rides/:id/complete
// @desc    Completar un viaje
// @access  Private (Driver only)
router.put('/:id/complete', protect, isDriver, async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);

    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Viaje no encontrado'
      });
    }

    if (ride.driver.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'No autorizado'
      });
    }

    if (ride.status !== 'in_progress') {
      return res.status(400).json({
        success: false,
        message: 'El viaje debe estar en progreso'
      });
    }

    ride.status = 'completed';
    ride.completedAt = Date.now();
    ride.paymentStatus = 'completed';
    await ride.save();

    // Incrementar contador de viajes
    await User.findByIdAndUpdate(ride.passenger, { $inc: { totalRides: 1 } });
    await User.findByIdAndUpdate(ride.driver, { $inc: { totalRides: 1 } });

    await ride.populate(['passenger', 'driver'], 'name phone rating vehicleInfo');

    res.json({
      success: true,
      message: 'Viaje completado',
      data: ride
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al completar viaje',
      error: error.message
    });
  }
});

// @route   PUT /api/rides/:id/cancel
// @desc    Cancelar un viaje
// @access  Private
router.put('/:id/cancel', protect, async (req, res) => {
  try {
    const { reason } = req.body;
    const ride = await Ride.findById(req.params.id);

    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Viaje no encontrado'
      });
    }

    // Verificar que el usuario es pasajero o conductor del viaje
    const isPassenger = ride.passenger.toString() === req.user._id.toString();
    const isDriver = ride.driver && ride.driver.toString() === req.user._id.toString();

    if (!isPassenger && !isDriver) {
      return res.status(403).json({
        success: false,
        message: 'No autorizado'
      });
    }

    if (ride.status === 'completed' || ride.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'No se puede cancelar este viaje'
      });
    }

    ride.status = 'cancelled';
    ride.cancelledAt = Date.now();
    ride.cancelledBy = req.user.userType;
    ride.cancellationReason = reason || 'Sin motivo especificado';
    await ride.save();

    await ride.populate(['passenger', 'driver'], 'name phone rating vehicleInfo');

    res.json({
      success: true,
      message: 'Viaje cancelado',
      data: ride
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al cancelar viaje',
      error: error.message
    });
  }
});

// @route   PUT /api/rides/:id/rate
// @desc    Calificar un viaje
// @access  Private
router.put('/:id/rate', protect, async (req, res) => {
  try {
    const { rating, comment } = req.body;
    const ride = await Ride.findById(req.params.id);

    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Viaje no encontrado'
      });
    }

    if (ride.status !== 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Solo se pueden calificar viajes completados'
      });
    }

    // Validar rating
    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'La calificación debe ser entre 1 y 5'
      });
    }

    const isPassenger = ride.passenger.toString() === req.user._id.toString();
    const isDriver = ride.driver && ride.driver.toString() === req.user._id.toString();

    if (!isPassenger && !isDriver) {
      return res.status(403).json({
        success: false,
        message: 'No autorizado'
      });
    }

    if (isPassenger) {
      // Pasajero califica al conductor
      if (ride.passengerRating) {
        return res.status(400).json({
          success: false,
          message: 'Ya calificaste este viaje'
        });
      }
      ride.passengerRating = rating;
      ride.passengerComment = comment;
      
      // Actualizar rating del conductor
      const driver = await User.findById(ride.driver);
      await driver.updateRating(rating);
    } else {
      // Conductor califica al pasajero
      if (ride.driverRating) {
        return res.status(400).json({
          success: false,
          message: 'Ya calificaste este viaje'
        });
      }
      ride.driverRating = rating;
      ride.driverComment = comment;
      
      // Actualizar rating del pasajero
      const passenger = await User.findById(ride.passenger);
      await passenger.updateRating(rating);
    }

    await ride.save();
    await ride.populate(['passenger', 'driver'], 'name phone rating vehicleInfo');

    res.json({
      success: true,
      message: 'Calificación guardada',
      data: ride
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al calificar viaje',
      error: error.message
    });
  }
});

// @route   GET /api/rides/my-rides
// @desc    Obtener viajes del usuario
// @access  Private
router.get('/my-rides', protect, async (req, res) => {
  try {
    const { status, limit = 20, page = 1 } = req.query;
    
    const query = {};
    
    if (req.user.userType === 'passenger') {
      query.passenger = req.user._id;
    } else {
      query.driver = req.user._id;
    }

    if (status) {
      query.status = status;
    }

    const rides = await Ride.find(query)
      .populate('passenger', 'name phone rating')
      .populate('driver', 'name phone rating vehicleInfo')
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit));

    const total = await Ride.countDocuments(query);

    res.json({
      success: true,
      count: rides.length,
      total,
      page: parseInt(page),
      pages: Math.ceil(total / parseInt(limit)),
      data: rides
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al obtener viajes',
      error: error.message
    });
  }
});

// @route   GET /api/rides/:id
// @desc    Obtener detalle de un viaje
// @access  Private
router.get('/:id', protect, async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id)
      .populate('passenger', 'name phone rating profilePhoto')
      .populate('driver', 'name phone rating vehicleInfo profilePhoto');

    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Viaje no encontrado'
      });
    }

    // Verificar que el usuario tiene acceso a este viaje
    const isPassenger = ride.passenger._id.toString() === req.user._id.toString();
    const isDriver = ride.driver && ride.driver._id.toString() === req.user._id.toString();

    if (!isPassenger && !isDriver) {
      return res.status(403).json({
        success: false,
        message: 'No autorizado'
      });
    }

    res.json({
      success: true,
      data: ride
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al obtener viaje',
      error: error.message
    });
  }
});

// @route   GET /api/rides/available/list
// @desc    Obtener viajes disponibles para conductores
// @access  Private (Driver only)
router.get('/available/list', protect, isDriver, async (req, res) => {
  try {
    const { latitude, longitude, radius = 10000 } = req.query; // Radio en metros

    const query = {
      status: 'requested',
      driver: null
    };

    // Si se proporcionan coordenadas, buscar viajes cercanos
    if (latitude && longitude) {
      query['pickupLocation.coordinates'] = {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(longitude), parseFloat(latitude)]
          },
          $maxDistance: parseInt(radius)
        }
      };
    }

    const rides = await Ride.find(query)
      .populate('passenger', 'name phone rating')
      .sort({ requestedAt: -1 })
      .limit(10);

    res.json({
      success: true,
      count: rides.length,
      data: rides
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al obtener viajes disponibles',
      error: error.message
    });
  }
});

module.exports = router;
