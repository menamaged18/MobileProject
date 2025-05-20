// src/modules/inventory/inventory.controller.js
import { Router } from "express";
import {
  getAllInventories,
  getInventoryById,
  createInventory,
  updateInventory,
  deleteInventory,
  getStoreProducts,
  getProductStores
} from "./service/inventory.service.js";

const router = Router();

// GET /inventories
router.get("/", getAllInventories);

// GET /inventories/store/:storeID/products
router.get("/store/:storeID/products", getStoreProducts);

// GET /inventories/:id
router.get("/:id", getInventoryById);

// POST /inventories
router.post("/", createInventory);

// PUT /inventories/:id
router.put("/:id", updateInventory);

// DELETE /inventories/:id
router.delete("/:id", deleteInventory);

// 
router.get("/product/:productID/stores", getProductStores);

export default router;