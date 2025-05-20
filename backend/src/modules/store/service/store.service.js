// modules/store/service/store.service.js
import { asyncHandler } from "../../../utilis/response/error.response.js";
import { successRespone } from "../../../utilis/response/success.response.js";
import { ErrorResponse } from '../../../utilis/response/error.response.js';
import * as dbService from "../../../DB/db.service.js";
import { Store } from "../../../DB/model/store.model.js";

// =============================
// Get all stores
// =============================
export const getAllStores = asyncHandler(async (req, res, next) => {
  const stores = await dbService.find({ model: Store });
  return successRespone({ res, data: { stores } });
});

// =============================
// Get store by ID
// =============================
export const getStoreById = asyncHandler(async (req, res, next) => {
  const storeId = Number(req.params.id);
  
  // Check if storeId is a valid number
  if (isNaN(storeId)) {
    return next(new Error('Invalid store ID format'));
  }
  
  // Find store by storeID field instead of _id
  const store = await dbService.findOne({ 
    model: Store, 
    filter: { storeID: storeId }
  });
  
  if (!store) {
    return next(new Error("Store not found"));
  }
  
  return successRespone({ res, data: { store } });
});

// =============================
// Create store
// =============================
export const createStore = asyncHandler(async (req, res, next) => {
  let { name, address, location } = req.body;

  // If location was sent as a JSON string (form-data), parse it
  if (typeof location === 'string') {
    try {
      location = JSON.parse(location);
    } catch (err) {
      return next(
        new ErrorResponse(
          'Invalid location JSON. Use { "type": "Point", "coordinates": [long,lat] }',
          400
        )
      );
    }
  }

  // Validate location format
  if (
    !location?.coordinates ||
    !Array.isArray(location.coordinates) ||
    location.coordinates.length !== 2
  ) {
    return next(
      new ErrorResponse(
        'Invalid location format. Use { type: "Point", coordinates: [long, lat] }',
        400
      )
    );
  }

  // Build store data, include image URL if a file was uploaded
  const storeData = {
    name,
    address,
    location,
    // storing storeImage
    ...(req.file && {
      storeImage: `${process.env.BASE_URL || ''}/uploads/${req.file.filename}`
    })
  };

  // Create the store document
  const store = await dbService.create({
    model: Store,
    data: storeData
  });

  // Send success response
  return successRespone({ res, data: { store } });
});

// =============================
// Update store
// =============================
export const updateStore = asyncHandler(async (req, res, next) => {
  const storeId = Number(req.params.id);
  
  // Check if storeId is a valid number
  if (isNaN(storeId)) {
    return next(new Error('Invalid store ID format'));
  }
  
  const { name, address, location } = req.body;
  
  // Find and update by storeID field instead of _id
  const updatedStore = await dbService.findOneAndUpdate({ 
    model: Store, 
    filter: { storeID: storeId }, 
    data: { name, address, location }
  });
  
  if (!updatedStore) {
    return next(new Error("Store not found"));
  }
  
  return successRespone({ res, data: { store: updatedStore } });
});

// =============================
// Delete store
// =============================
export const deleteStore = asyncHandler(async (req, res, next) => {
  const storeId = req.params.id;
  await dbService.findByIdAndDelete({ model: Store, id: storeId });
  return successRespone({ res, data: { message: "Store deleted successfully" } });
});




