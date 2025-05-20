// DB/modules/user/service/user.service.js
import multer from "multer";
import path from "path";
import { asyncHandler } from "../../../utilis/response/error.response.js";
import { successRespone } from "../../../utilis/response/success.response.js";
import * as dbService from "../../../DB/db.service.js";
import { userModel } from "../../../DB/model/User.model.js";
import bcrypt from "bcryptjs";
import { Counter } from "../../../DB/model/counter.model.js";

// =============================
// Profile function
// =============================
export const profile = asyncHandler(async (req, res, next) => {
  const user = await dbService.findOne({
    model: userModel,
    filter: { _id: req.user._id },
    select: "-password -createdAt -updatedAt"
  });
  return successRespone({ res, data: { user } });
});

// =============================
// Update user details (name, email, etc.)
// =============================
export const updateUser = asyncHandler(async (req, res, next) => {
  const userId = req.params.id;
  const { name, gender, email, level, password } = req.body;

  // Hash password if provided
  let hashedPassword = undefined;
  if (password) {
    hashedPassword = await bcrypt.hash(password, 10);
  }

  // Build update data
  const updateData = {
    name,
    gender,
    email,
    level,
    ...(hashedPassword && { password: hashedPassword })
  };

  const updatedUser = await dbService.findByIdAndUpdate({
    model: userModel,
    id: userId,
    data: updateData,
    options: { new: true },
  });

  return successRespone({ res, data: { user: updatedUser } });
});

// =============================
// Multer Disk‐Storage Config
// =============================
const diskStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(process.cwd(), "uploads"));
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  }
});

// **Exported** as `upload` so your controller import matches
export const upload = multer({
  storage: diskStorage,
  fileFilter: (req, file, cb) =>
    file.mimetype.startsWith("image/")
      ? cb(null, true)
      : cb(new Error("Only image files are allowed!"), false),
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB
});

// =============================
// Update Profile Image (store path)
// =============================
export const updateProfileImage = asyncHandler(async (req, res, next) => {
  if (!req.file) {
    return next(new Error("No image uploaded"));
  }

  // Builds a URL like: "http://localhost:3000/uploads/12345-my.png"
  const imagePath = `${process.env.BASE_URL || ""}/uploads/${req.file.filename}`;

  const updatedUser = await dbService.findByIdAndUpdate({
    model: userModel,
    id: req.user._id,
    data: { imageProfile: imagePath },
    options: { new: true }
  });

  return successRespone({
    res,
    data: {
      imageUrl: imagePath,
      user: updatedUser
    }
  });
});

// =============================
// Get Profile Image URL
// =============================
export const getProfileImage = asyncHandler(async (req, res, next) => {
  const user = await dbService.findOne({
    model: userModel,
    filter: { _id: req.user._id },
    select: "imageProfile"
  });

  if (!user || !user.imageProfile) {
    return next(new Error("No profile image found"));
  }

  return successRespone({ res, data: { imageUrl: user.imageProfile } });
});

// ==================================================================
// new codes to handle favourite stores 
// ==================================================================

// =============================
// Add favorite store
// =============================
export const addFavoriteStore = asyncHandler(async (req, res, next) => {
  const userId = req.user._id;
  const storeId = req.params.storeId;

  const updatedUser = await dbService.findByIdAndUpdate({
    model: userModel,
    id: userId,
    data: { $addToSet: { favoriteStores: storeId } },
    options: { new: true }
  });

  return successRespone({ res, data: { user: updatedUser } });
});

// =============================
// Remove favorite store
// =============================
export const removeFavoriteStore = asyncHandler(async (req, res, next) => {
  const userId = req.user._id;
  const storeId = req.params.storeId;

  const updatedUser = await dbService.findByIdAndUpdate({
    model: userModel,
    id: userId,
    data: { $pull: { favoriteStores: storeId } },
    options: { new: true }
  });

  return successRespone({ res, data: { user: updatedUser } });
});

// =============================
// Get favorite stores
// =============================
export const getFavoriteStores = asyncHandler(async (req, res, next) => {
  const user = await dbService.findOne({
    model: userModel,
    filter: { _id: req.user._id },
    populate: { path: 'favoriteStores' }
  });

  return successRespone({ res, data: { favoriteStores: user.favoriteStores } });
});

// =============================
// Get userID
// =============================
export async function getNextUserID(req, res, next) {
  try {
    // find the counter doc (but don’t increment)
    const counter = await Counter.findById("userID").lean();
    const nextID = (counter?.seq || 0) + 1;
    return res.status(200).json({ data: { nextUserID: nextID } });
  } catch (err) {
    next(err);
  }
}