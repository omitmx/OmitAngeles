const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Middleware para verificar token JWT
const protect = async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // Obtener token del header
      token = req.headers.authorization.split(' ')[1];

      // Verificar token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Obtener usuario del token (sin contraseña)
      req.user = await User.findById(decoded.id).select('-password');

      if (!req.user) {
        return res.status(401).json({
          success: false,
          message: 'Usuario no encontrado'
        });
      }

      next();
    } catch (error) {
      console.error(error);
      return res.status(401).json({
        success: false,
        message: 'No autorizado, token inválido'
      });
    }
  }

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'No autorizado, no hay token'
    });
  }
};

// Middleware para verificar que el usuario es conductor
const isDriver = (req, res, next) => {
  if (req.user && req.user.userType === 'driver') {
    next();
  } else {
    res.status(403).json({
      success: false,
      message: 'Acceso denegado. Solo conductores.'
    });
  }
};

// Middleware para verificar que el usuario es pasajero
const isPassenger = (req, res, next) => {
  if (req.user && req.user.userType === 'passenger') {
    next();
  } else {
    res.status(403).json({
      success: false,
      message: 'Acceso denegado. Solo pasajeros.'
    });
  }
};

module.exports = { protect, isDriver, isPassenger };
