// DB/model/store.model.js
import mongoose from 'mongoose';
import { Counter } from './counter.model.js';

const storeSchema = new mongoose.Schema({
  storeID: { 
    type: Number,
    unique: true 
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  address: {
    type: String,
    required: true
  },
  storeImage: {
    type: String,
    default: null
  },
  location: {
    type: {
      type: String,
      default: 'Point',
      enum: ['Point']
    },
    coordinates: [Number] // [longitude, latitude]
  },
  // Array of product references
  // products: [{
  //   type: mongoose.Schema.Types.ObjectId,
  //   ref: 'Product'
  // }]
});

// Auto-increment logic for storeID
storeSchema.pre('save', async function(next) {
  if (this.isNew) {
    const counter = await Counter.findByIdAndUpdate(
      'storeID', // Unique identifier for store counter
      { $inc: { seq: 1 } },
      { new: true, upsert: true }
    );
    this.storeID = counter.seq;
  }
  next();
});

// Index for geospatial queries
storeSchema.index({ location: '2dsphere' });

export const Store = mongoose.model('Store', storeSchema);