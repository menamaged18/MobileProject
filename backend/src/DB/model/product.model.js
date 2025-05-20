// DB/model/product.model.js
import mongoose from 'mongoose';
import { Counter } from './counter.model.js';

const productSchema = new mongoose.Schema({
  productID: { 
    type: Number,
    unique: true 
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    default: ''
  },
  image: {
    type: String,
    default: null
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Auto-increment logic for productID
productSchema.pre('save', async function(next) {
  if (this.isNew) {
    const counter = await Counter.findByIdAndUpdate(
      'productID', // Unique identifier for product counter
      { $inc: { seq: 1 } },
      { new: true, upsert: true }
    );
    this.productID = counter.seq;
  }
  next();
});

export const Product = mongoose.model('Product', productSchema);