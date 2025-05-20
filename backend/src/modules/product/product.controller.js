// modules/product/product.controller.js
import { Router } from "express";
import multer from 'multer';
import {
  getAllProducts,
  getProductById,
  createProduct,
  updateProduct,
  deleteProduct
} from "./service/product.service.js";

const router = Router();

// configure storage/destination for product images
const storage = multer.diskStorage({
  destination: 'uploads/',
  filename: (req, file, cb) => {
    cb(null, file.originalname);
  }
});

const upload = multer({ storage });

// GET /products
router.get("/", getAllProducts);

// GET /products/:id
router.get("/:id", getProductById);

// POST /products
router.post("/", upload.single('image'), createProduct);

// PUT /products/:id
router.put("/:id", updateProduct);

// DELETE /products/:id
router.delete("/:id", deleteProduct);

export default router;