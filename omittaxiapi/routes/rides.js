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

    // Verificar que el pasajero no tenga un viaje activo
    const activeRide = await Ride.findOne({
      passenger: req.user._id,
      status: { $in: ['requested', 'accepted', 'arrived', 'in_progress'] }
    });

    if (activeRide) {
      console.log(`⚠️ Pasajero ${req.user.name} intentó solicitar viaje teniendo uno activo (${activeRide._id})`);
      return res.status(400).json({
        success: false,
        message: 'Ya tienes una solicitud de viaje activa. Completa o cancela tu viaje actual antes de solicitar uno nuevo.',
        activeRideId: activeRide._id
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

    console.log(`💰 Tarifa calculada: $${ride.fare.total} (base: $${ride.fare.baseFare}, distancia: $${ride.fare.distanceFare})`);

    await ride.save();

    // Poblar datos del pasajero
    await ride.populate('passenger', 'name phone rating');

    // Emitir evento WebSocket a conductores cercanos
    const io = req.app.get('io');
    if (io) {
      io.emit('ride:new-request', {
        rideId: ride._id.toString(),
        passenger: {
          id: ride.passenger._id,
          name: ride.passenger.name,
          phone: ride.passenger.phone,
          rating: ride.passenger.rating
        },
        pickup: {
          address: pickupAddress,
          lat: pickupLat,
          lng: pickupLng
        },
        dropoff: {
          address: dropoffAddress,
          lat: dropoffLat,
          lng: dropoffLng
        },
        distance: distance,
        fare: ride.fare,
        estimatedDuration: estimatedDuration
      });
      console.log(`📢 Nueva solicitud broadcast a conductores: ${ride._id}`);
    }

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

// @route   GET /api/rides/available
// @desc    Obtener viajes disponibles (solicitudes pendientes)
// @access  Private (Driver only)
router.get('/available', protect, isDriver, async (req, res) => {
  try {
    // Obtener solicitudes con status 'requested'
    const rides = await Ride.find({ status: 'requested' })
      .populate('passenger', 'name phone rating')
      .sort({ requestedAt: -1 })
      .limit(20);

    console.log(`📋 ${rides.length} solicitudes disponibles para conductor ${req.user._id}`);

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

// @route   PUT /api/rides/:id/accept
// @desc    Aceptar un viaje (conductor)
// @access  Private (Driver only)
router.put('/:id/accept', protect, isDriver, async (req, res) => {
  try {
    // Verificar que el conductor no tenga un viaje activo
    const activeDriverRide = await Ride.findOne({
      driver: req.user._id,
      status: { $in: ['accepted', 'arrived', 'in_progress'] }
    });

    if (activeDriverRide) {
      console.log(`⚠️ Conductor ${req.user.name} intentó aceptar viaje teniendo uno activo (${activeDriverRide._id})`);
      return res.status(400).json({
        success: false,
        message: 'Ya tienes un viaje activo. Completa o cancela tu viaje actual antes de aceptar uno nuevo.',
        activeRideId: activeDriverRide._id
      });
    }

    // Usar findOneAndUpdate para operación atómica (evita que dos conductores tomen el mismo viaje)
    const ride = await Ride.findOneAndUpdate(
      {
        _id: req.params.id,
        status: 'requested' // Solo actualizar si aún está en estado requested
      },
      {
        driver: req.user._id,
        status: 'accepted',
        acceptedAt: Date.now()
      },
      {
        new: true // Retornar el documento actualizado
      }
    );

    if (!ride) {
      console.log(`⚠️ Conductor ${req.user.name} intentó aceptar viaje ${req.params.id} pero ya no está disponible`);
      return res.status(400).json({
        success: false,
        message: 'Este viaje ya fue tomado por otro conductor o no está disponible'
      });
    }

    await ride.populate(['passenger', 'driver'], 'name phone rating vehicleInfo economicNumber');

    // Emitir evento WebSocket al pasajero
    const io = req.app.get('io');
    if (io) {
      const eventData = {
        rideId: ride._id.toString(),
        passengerId: ride.passenger._id.toString(),
        driver: {
          id: ride.driver._id.toString(),
          name: ride.driver.name,
          phone: ride.driver.phone,
          rating: ride.driver.rating,
          vehicleInfo: ride.driver.vehicleInfo,
          economicNumber: ride.driver.economicNumber
        }
      };
      
      // Emitir a todos los clientes conectados
      io.emit('ride:accepted', eventData);
      
      // También emitir específicamente al pasajero
      io.to(ride.passenger._id.toString()).emit('ride:accepted', eventData);
      
      console.log(`✅ Viaje ${ride._id} aceptado por conductor ${ride.driver.name} (Unidad #${ride.driver.economicNumber || 'N/A'})`);
      console.log(`📢 Evento 'ride:accepted' emitido al pasajero ${ride.passenger._id}`);
    }

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

// @route   PUT /api/rides/:id/arrive
// @desc    Marcar que el conductor llegó al punto de recogida
// @access  Private (Driver only)
router.put('/:id/arrive', protect, isDriver, async (req, res) => {
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

    if (ride.status !== 'accepted') {
      return res.status(400).json({
        success: false,
        message: 'El viaje debe estar en estado aceptado'
      });
    }

    ride.status = 'arrived';
    ride.arrivedAt = Date.now();
    await ride.save();

    await ride.populate(['passenger', 'driver'], 'name phone rating vehicleInfo');

    // Emitir evento WebSocket al pasajero
    const io = req.app.get('io');
    if (io) {
      const eventData = {
        rideId: ride._id.toString(),
        passengerId: ride.passenger._id.toString(),
        driver: {
          id: ride.driver._id.toString(),
          name: ride.driver.name,
          phone: ride.driver.phone,
        }
      };
      
      // Emitir a todos los clientes conectados
      io.emit('driver:arrived', eventData);
      
      // También emitir específicamente al pasajero
      io.to(ride.passenger._id.toString()).emit('driver:arrived', eventData);
      
      console.log(`🏁 Conductor ${ride.driver.name} llegó al punto de recogida`);
      console.log(`📢 Evento 'driver:arrived' emitido al pasajero ${ride.passenger._id}`);
    }

    res.json({
      success: true,
      message: 'Llegada confirmada',
      data: ride
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al confirmar llegada',
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
// @desc    Completar un viaje (confirmación del pasajero después de que el conductor llegó)
// @access  Private (Passenger or Driver)
router.put('/:id/complete', protect, async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);

    if (!ride) {
      return res.status(404).json({
        success: false,
        message: 'Viaje no encontrado'
      });
    }

    // Verificar que sea el pasajero o el conductor del viaje
    const isPassenger = ride.passenger.toString() === req.user._id.toString();
    const isDriver = ride.driver.toString() === req.user._id.toString();

    if (!isPassenger && !isDriver) {
      return res.status(403).json({
        success: false,
        message: 'No autorizado'
      });
    }

    // El viaje debe estar en estado 'arrived' para ser completado por el pasajero
    if (ride.status !== 'arrived') {
      return res.status(400).json({
        success: false,
        message: 'El viaje debe estar en estado "arrived" para ser completado'
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

    // Emitir evento a ambas partes
    const io = req.app.get('io');
    io.emit('ride:completed', {
      rideId: ride._id,
      passengerId: ride.passenger._id,
      driverId: ride.driver._id,
      passenger: {
        id: ride.passenger._id,
        name: ride.passenger.name,
        phone: ride.passenger.phone
      },
      driver: {
        id: ride.driver._id,
        name: ride.driver.name,
        phone: ride.driver.phone
      }
    });

    console.log(`✅ Viaje ${ride._id} completado por ${isPassenger ? 'pasajero' : 'conductor'} ${req.user.name}`);

    res.json({
      success: true,
      message: 'Viaje completado exitosamente',
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

    await ride.populate(['passenger', 'driver'], 'name phone rating vehicleInfo economicNumber');

    // Emitir evento de cancelación por WebSocket
    const io = req.app.get('io');
    if (io) {
      const eventData = {
        rideId: ride._id,
        status: 'cancelled',
        cancelledBy: req.user.userType,
        reason: ride.cancellationReason,
        passenger: {
          id: ride.passenger._id,
          name: ride.passenger.name,
          phone: ride.passenger.phone,
        },
        driver: ride.driver ? {
          id: ride.driver._id,
          name: ride.driver.name,
          phone: ride.driver.phone,
          economicNumber: ride.driver.economicNumber,
        } : null
      };

      // Emitir a todos
      io.emit('ride:cancelled', eventData);
      
      // Emitir específicamente al pasajero y conductor
      io.to(ride.passenger._id.toString()).emit('ride:cancelled', eventData);
      if (ride.driver) {
        io.to(ride.driver._id.toString()).emit('ride:cancelled', eventData);
      }

      console.log(`❌ Viaje ${ride._id} cancelado por ${req.user.userType}: ${req.user.name}`);
      console.log(`📢 Evento 'ride:cancelled' emitido`);
    }

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

// @route   GET /api/rides/active/check
// @desc    Verificar si el usuario tiene un viaje activo
// @access  Private
router.get('/active/check', protect, async (req, res) => {
  try {
    const query = {
      status: { $in: ['requested', 'accepted', 'arrived', 'in_progress'] }
    };
    
    if (req.user.userType === 'passenger') {
      query.passenger = req.user._id;
    } else {
      query.driver = req.user._id;
    }

    const activeRide = await Ride.findOne(query)
      .populate('passenger', 'name phone rating')
      .populate('driver', 'name phone rating vehicleInfo economicNumber')
      .sort({ createdAt: -1 });

    if (activeRide) {
      res.json({
        success: true,
        hasActiveRide: true,
        data: activeRide
      });
    } else {
      res.json({
        success: true,
        hasActiveRide: false,
        data: null
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al verificar viaje activo',
      error: error.message
    });
  }
});

// @route   GET /api/rides/:id
// @desc    Obtener detalle de un viaje
// @access  Private
// NOTA: Esta ruta debe ir al FINAL para no interceptar rutas específicas como /available
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

module.exports = router;
