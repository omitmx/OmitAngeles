const mongoose = require('mongoose');

const rideSchema = new mongoose.Schema({
  passenger: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  driver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  pickupLocation: {
    address: {
      type: String,
      required: true
    },
    coordinates: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point'
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true
      }
    }
  },
  dropoffLocation: {
    address: {
      type: String,
      required: true
    },
    coordinates: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point'
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true
      }
    }
  },
  distance: {
    type: Number, // en kilómetros
    default: 0
  },
  estimatedDuration: {
    type: Number, // en minutos
    default: 0
  },
  fare: {
    baseFare: {
      type: Number,
      default: 20
    },
    distanceFare: {
      type: Number,
      default: 0
    },
    total: {
      type: Number,
      required: true
    }
  },
  status: {
    type: String,
    enum: ['requested', 'accepted', 'arrived', 'in_progress', 'completed', 'cancelled'],
    default: 'requested'
  },
  paymentMethod: {
    type: String,
    enum: ['cash', 'card', 'wallet'],
    default: 'cash'
  },
  paymentStatus: {
    type: String,
    enum: ['pending', 'completed', 'refunded'],
    default: 'pending'
  },
  passengerRating: {
    type: Number,
    min: 1,
    max: 5,
    default: null
  },
  driverRating: {
    type: Number,
    min: 1,
    max: 5,
    default: null
  },
  passengerComment: {
    type: String,
    default: null
  },
  driverComment: {
    type: String,
    default: null
  },
  requestedAt: {
    type: Date,
    default: Date.now
  },
  acceptedAt: {
    type: Date,
    default: null
  },
  startedAt: {
    type: Date,
    default: null
  },
  completedAt: {
    type: Date,
    default: null
  },
  cancelledAt: {
    type: Date,
    default: null
  },
  cancelledBy: {
    type: String,
    enum: ['passenger', 'driver', 'system'],
    default: null
  },
  cancellationReason: {
    type: String,
    default: null
  }
}, {
  timestamps: true
});

// Índices para búsquedas eficientes
rideSchema.index({ passenger: 1, createdAt: -1 });
rideSchema.index({ driver: 1, createdAt: -1 });
rideSchema.index({ status: 1 });
rideSchema.index({ 'pickupLocation.coordinates': '2dsphere' });

// Método para calcular tarifa
rideSchema.methods.calculateFare = function(baseFare = 20, farePerKm = 8) {
  this.fare.baseFare = baseFare;
  this.fare.distanceFare = this.distance * farePerKm;
  this.fare.total = this.fare.baseFare + this.fare.distanceFare;
  return this.fare.total;
};

const Ride = mongoose.model('Ride', rideSchema);

module.exports = Ride;
