import { Router } from "express";
import { getAllStores, getStoreById, createStore, updateStore, deleteStore } from "./service/store.service.js";
import multer from 'multer';

const router = Router();

// configure your storage/destination 
const storage = multer.diskStorage({
    destination: 'uploads/',
    filename: (req, file, cb) => {
      cb(null, file.originalname); // or any naming convention you prefer
    }
});
  
const upload = multer({ storage });

// GET /stores
router.get("/", getAllStores);

// GET /stores/:id
router.get("/:id", getStoreById);

// POST /stores
// router.post("/", createStore);
router.post("/", upload.single('storeImage'), createStore);


// PUT /stores/:id
router.put("/:id", updateStore);

// DELETE /stores/:id
router.delete("/:id", deleteStore);

export default router;