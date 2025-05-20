import joi from "joi";
import { generalFields } from "../../middleware/validation.middleware.js";

export const signup = joi.object().keys({
    name: generalFields.name.required(),
    gender: generalFields.gender, 
    email: generalFields.email.required(),
    level: generalFields.level, 
    password: generalFields.password.required(),
    confirmPassword: generalFields.confirmPassword.required(),
}).required();


export const login = joi.object().keys({
    email: generalFields.email.required(),
    password: generalFields.password.required(),
}).required();
