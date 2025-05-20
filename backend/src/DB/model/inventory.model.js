// every store should have its products and there could be a product in store1 and store2 
// for example tea could be in store1 with price:10 and also in store2 with price:20
// this is a many to many relationship and we need this model to overcome this problem
// DB/model/inventory.model.js

import mongoose from 'mongoose';

const inventorySchema = new mongoose.Schema({
  store: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Store',
    required: true
  },
  product: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true
  },
  price: {
    type: Number,
    required: true,
    min: 0
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// prevent the same product being added twice to one store
inventorySchema.index({ store: 1, product: 1 }, { unique: true });

export const Inventory = mongoose.model('Inventory', inventorySchema);
 