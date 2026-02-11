const express = require('express');
const router = express.Router();
const User = require('../models/User');
const { protect, isDriver } = require('../middleware/auth');

// @route   PUT /api/drivers/online
// @desc    Poner conductor en línea
// @access  Private (Driver only)
router.put('/online', protect, isDriver, async (req, res) => {
  try {
    const { latitude, longitude } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Se requieren coordenadas de ubicación'
      });
    }

    const driver = await User.findByIdAndUpdate(
      req.user._id,
      {
        isOnline: true,
        currentLocation: {
          type: 'Point',
          coordinates: [longitude, latitude]
        }
      },
      { new: true }
    );

    res.json({
      success: true,
      message: 'Conductor en línea',
      data: driver
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al actualizar estado',
      error: error.message
    });
  }
});

// @route   PUT /api/drivers/offline
// @desc    Poner conductor fuera de línea
// @access  Private (Driver only)
router.put('/offline', protect, isDriver, async (req, res) => {
  try {
    const driver = await User.findByIdAndUpdate(
      req.user._id,
      { isOnline: false },
      { new: true }
    );

    res.json({
      success: true,
      message: 'Conductor fuera de línea',
      data: driver
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al actualizar estado',
      error: error.message
    });
  }
});

// @route   PUT /api/drivers/location
// @desc    Actualizar ubicación del conductor
// @access  Private (Driver only)
router.put('/location', protect, isDriver, async (req, res) => {
  try {
    const { latitude, longitude } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Se requieren coordenadas de ubicación'
      });
    }

    const driver = await User.findByIdAndUpdate(
      req.user._id,
      {
        currentLocation: {
          type: 'Point',
          coordinates: [longitude, latitude]
        }
      },
      { new: true }
    );

    res.json({
      success: true,
      data: {
        location: driver.currentLocation
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al actualizar ubicación',
      error: error.message
    });
  }
});

// @route   GET /api/drivers/nearby
// @desc    Buscar conductores cercanos
// @access  Private
router.get('/nearby', protect, async (req, res) => {
  try {
    const { latitude, longitude, radius = 5000 } = req.query; // Radio en metros

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Se requieren coordenadas de ubicación'
      });
    }

    const drivers = await User.find({
      userType: 'driver',
      isOnline: true,
      isActive: true,
      currentLocation: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(longitude), parseFloat(latitude)]
          },
          $maxDistance: parseInt(radius)
        }
      }
    }).select('name rating totalRides vehicleInfo currentLocation');

    res.json({
      success: true,
      count: drivers.length,
      data: drivers
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error al buscar conductores',
      error: error.message
    });
  }
});

module.exports = router;
