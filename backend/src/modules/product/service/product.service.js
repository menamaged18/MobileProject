// modules/product/service/product.service.js
import { asyncHandler } from "../../../utilis/response/error.response.js";
import { successRespone } from "../../../utilis/response/success.response.js";
import { ErrorResponse } from "../../../utilis/response/error.response.js";
import * as dbService from "../../../DB/db.service.js";
import { Product } from "../../../DB/model/product.model.js";

// =============================
// Get all products
// =============================
export const getAllProducts = asyncHandler(async (req, res, next) => {
  const products = await dbService.find({ model: Product });
  return successRespone({ res, data: { products } });
});

// =============================
// Get product by ID
// =============================
export const getProductById = asyncHandler(async (req, res, next) => {
  const productId = Number(req.params.id);
  
  // Check if productId is a valid number
  if (isNaN(productId)) {
    return next(new ErrorResponse('Invalid product ID format', 400));
  }
  
  // Find product by productID field instead of _id
  const product = await dbService.findOne({ 
    model: Product, 
    filter: { productID: productId }
  });
  
  if (!product) {
    return next(new ErrorResponse('Product not found', 404));
  }
  
  return successRespone({ res, data: { product } });
});

// =============================
// Create product
// =============================
export const createProduct = asyncHandler(async (req, res, next) => {
  let { name, description } = req.body;

  // Build product data, include image URL if a file was uploaded
  const productData = {
    name,
    description,
    ...(req.file && {
      image: `${process.env.BASE_URL || ''}/uploads/${req.file.filename}`
    })
  };

  // Create the product document
  const product = await dbService.create({ model: Product, data: productData });

  // Send success response
  return successRespone({ res, data: { product } });
});

// =============================
// Update product
// =============================
export const updateProduct = asyncHandler(async (req, res, next) => {
  const productId = Number(req.params.id);
  
  // Check if productId is a valid number
  if (isNaN(productId)) {
    return next(new ErrorResponse('Invalid product ID format', 400));
  }
  
  const { name, description, price } = req.body;
  
  // Find and update by productID field instead of _id
  const updated = await dbService.findOneAndUpdate({ 
    model: Product, 
    filter: { productID: productId }, 
    data: { name, description, price }
  });
  
  if (!updated) {
    return next(new ErrorResponse('Product not found', 404));
  }
  
  return successRespone({ res, data: { product: updated } });
});

// =============================
// Delete product
// =============================
export const deleteProduct = asyncHandler(async (req, res, next) => {
  const productId = req.params.id;
  await dbService.findByIdAndDelete({ model: Product, id: productId });
  return successRespone({ res, data: { message: 'Product deleted successfully' } });
});