// src/modules/inventory/service/inventory.service.js
import { asyncHandler } from "../../../utilis/response/error.response.js";
import { successRespone } from "../../../utilis/response/success.response.js";
import { ErrorResponse } from "../../../utilis/response/error.response.js";
import * as dbService from "../../../DB/db.service.js";
import { Inventory } from "../../../DB/model/inventory.model.js";
import { Store } from "../../../DB/model/store.model.js";
import { Product } from "../../../DB/model/product.model.js";

// =============================
// Get all inventory entries
// =============================
export const getAllInventories = asyncHandler(async (req, res, next) => {
  const inventories = await dbService.find({ model: Inventory });
  return successRespone({ res, data: { inventories } });
});

// =============================
// Get inventory by ID
// =============================
export const getInventoryById = asyncHandler(async (req, res, next) => {
  const inventory = await dbService.findOne({
    model: Inventory,
    filter: { _id: req.params.id }
  });
  
  if (!inventory) {
    return next(new ErrorResponse('Inventory entry not found', 404));
  }
  
  return successRespone({ res, data: { inventory } });
});

// =============================
// Get all products in a specific store
// =============================
export const getStoreProducts = asyncHandler(async (req, res, next) => {
  const storeID = Number(req.params.storeID);
  
  if (isNaN(storeID)) {
    return next(new ErrorResponse('Invalid store ID format', 400));
  }

  // Find store by numeric ID
  const store = await Store.findOne({ storeID });
  if (!store) {
    return next(new ErrorResponse('Store not found', 404));
  }

  // Find inventory entries and populate product details
  const inventories = await Inventory.find({ store: store._id })
    .populate({
      path: 'product',
      select: 'productID name description image'
    });

  // Transform results to include productID and filter necessary fields
  const products = inventories.map(inventory => ({
    ...inventory.product.toObject(),
    price: inventory.price,
    storeID: store.storeID,
    inventoryId: inventory._id
  }));

  return successRespone({ res, data: { products } });
});

// =============================
// Create inventory entry
// =============================
export const createInventory = asyncHandler(async (req, res, next) => {
  const { storeID, productID, price } = req.body;

  // Find store by numeric ID
  const store = await Store.findOne({ storeID });
  if (!store) {
    return next(new ErrorResponse('Store not found', 404));
  }

  // Find product by numeric ID
  const product = await Product.findOne({ productID });
  if (!product) {
    return next(new ErrorResponse('Product not found', 404));
  }

  try {
    const inventory = await dbService.create({
      model: Inventory,
      data: { 
        store: store._id, 
        product: product._id, 
        price 
      }
    });
    return successRespone({ res, data: { inventory } });
  } catch (error) {
    if (error.code === 11000) {
      return next(new ErrorResponse('This product already exists in the store', 400));
    }
    throw error;
  }
});

// =============================
// Update inventory entry
// =============================
export const updateInventory = asyncHandler(async (req, res, next) => {
  const inventory = await dbService.update({
    model: Inventory,
    filter: { _id: req.params.id },
    data: { price: req.body.price },
    options: { new: true }
  });

  if (!inventory) {
    return next(new ErrorResponse('Inventory entry not found', 404));
  }

  return successRespone({ res, data: { inventory } });
});

// =============================
// Delete inventory entry
// =============================
export const deleteInventory = asyncHandler(async (req, res, next) => {
  const inventory = await dbService.remove({
    model: Inventory,
    filter: { _id: req.params.id }
  });

  if (!inventory) {
    return next(new ErrorResponse('Inventory entry not found', 404));
  }

  return successRespone({ res, data: { inventory } });
});


// =============================
// Get all stores providing a specific product
// =============================
export const getProductStores = asyncHandler(async (req, res, next) => {
  const productID = Number(req.params.productID);
  
  if (isNaN(productID)) {
    return next(new ErrorResponse('Invalid product ID format', 400));
  }

  // Find product by numeric ID
  const product = await Product.findOne({ productID });
  if (!product) {
    return next(new ErrorResponse('Product not found', 404));
  }

  // Find inventory entries and populate store details
  const inventories = await Inventory.find({ product: product._id })
    .populate({
      path: 'store',
      select: 'storeID name address location storeImage'
    });

  // Transform results with store details and price
  const stores = inventories.map(inventory => ({
    ...inventory.store.toObject(),
    price: inventory.price,
    inventoryId: inventory._id
  }));

  return successRespone({ res, data: { stores } });
});