// app.controller.js
import connectDB from "./DB/connection.js";
import authController from "./modules/auth/auth.controller.js";
import userController from "./modules/user/user.controller.js";
import storeController from "./modules/store/store.controller.js";
import productController from "./modules/product/product.controller.js";
import inventoryRouter from './modules/inventory/inventory.controller.js';
import { globalErrorHandling } from "./utilis/response/error.response.js";
import cors from "cors";
import fs from "fs";
import path from "path";

const bootstrap = (app, express) => {
  const uploadsDir = path.join(process.cwd(), "uploads");
  if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
  }

  app.use(cors());
  app.use(express.json());

  // serve any files in uploads/ at GET /uploads/…
  app.use("/uploads", express.static(path.join(process.cwd(), "uploads")));


  // Mount your routers
  app.use("/auth", authController);
  app.use("/user", userController);
  app.use("/stores", storeController);
  app.use("/products", productController);
  app.use('/inventories', inventoryRouter);

  // 404 & error handling
  app.all("*", (req, res) =>
    res.status(404).json({ message: "Invalid routing" })
  );
  app.use(globalErrorHandling);

  connectDB();
};

export default bootstrap;
