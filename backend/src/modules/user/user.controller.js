import { Router } from "express";
import { authentication } from "../../middleware/auth.middleware.js";
import { 
  updateUser,
  profile,
  upload,              
  updateProfileImage,
  getProfileImage,
  addFavoriteStore,
  removeFavoriteStore,
  getFavoriteStores,
  getNextUserID
} from "./service/user.service.js";

const router = Router();

// GET /user/next-userid
router.get('/next-userid', getNextUserID);

// GET  /user/profile
router.get("/profile", authentication(), profile);

// PUT  /user/update/:id
router.put("/update/:id", authentication(), updateUser);

// POST /user/upload-image
//   • form‑field name must be "image"
//   • saves to /uploads and writes URL into imageProfile
router.post(
  "/upload-image",
  authentication(),
  upload.single("image"),
  updateProfileImage
);

// GET /user/profile-image
router.get("/profile-image", authentication(), getProfileImage);

// new routes to hanlde favourite store

// POST /user/favorite-stores/:storeId
router.post("/favorite-stores/:storeId", authentication(), addFavoriteStore);

// DELETE /user/favorite-stores/:storeId
router.delete("/favorite-stores/:storeId", authentication(), removeFavoriteStore);

// GET /user/favorite-stores
router.get("/favorite-stores", authentication(), getFavoriteStores);

export default router;

