import * as dotenv from "dotenv";
import path from "node:path";
import express from "express";
import bootstrap from "./src/app.controller.js";


dotenv.config({ path: path.resolve("./src/config/.env.dev") });

const app = express();
const port = process.env.PORT || 5000;

bootstrap(app, express);
app.listen(port, () => {
  console.log(`Example is running on port ${port}`);
});

