// auth.controller.js
import { Router } from "express";
import * as registrationService from "./service/registration.service.js";
import * as loginService from "./service/login.service.js";

import * as validators from "./auth.validation.js";
import { validation } from "../../middleware/validation.middleware.js";
const router = Router();

router.post("/signup", validation(validators.signup), registrationService.signup);
router.post("/login", validation(validators.login), loginService.login);

export default router;