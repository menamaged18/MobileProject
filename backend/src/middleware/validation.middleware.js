// validation.middleware.js this code handles FCAIStudentEmail
// import joi from "joi";
// import { genderTypes } from "../DB/model/User.model.js";

// const validateStudentEmail = (email, helpers) => {
//   const regex = /^(\d+)@stud\.fci-cu\.edu\.eg$/; 
//   const match = email.match(regex);
//   if (!match) {
//     return helpers.message("Email must follow the format studentID@stud.fci-cu.edu.eg");
//   }
//   return email;
// };


// export const isValidObjectId = (value, helper)=>{
//   return Types.ObjectId.isValid(value)? true : helper.message("In-valid object Id");
// }

// export const generalFields = {
//   name: joi.string().min(3).max(50).trim().required(),
//   gender: joi.string().valid(...Object.values(genderTypes)).optional(),
//   email: joi.string()
//     .required()
//     .custom(validateStudentEmail),
//   level: joi.number().valid(1, 2, 3, 4).optional(),
//   password: joi.string()
//     .required()
//     .pattern(new RegExp(/^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[#&<>@\"~;$^%{}?])(?=.*[a-zA-Z]).{8,}$/))
//     .messages({
//       "string.pattern.base": "Password must be at least 8 characters, include 1 uppercase, 1 lowercase, 1 number, and 1 special character."
//     }),
//   confirmPassword: joi.string()
//     .required()
//     .valid(joi.ref("password"))
//     .messages({
//       "any.only": "Confirm password must match password"
//     }),
//     id: joi.string().custom(isValidObjectId),
// };

// export const validation = (Schema) => {
//   return (req, res, next) => {
//     const inputs = { ...req.body, ...req.params, ...req.query };
//     const validationResult = Schema.validate(inputs, { abortEarly: false });
//     if (validationResult.error) {
//       return res.status(400).json({
//         message: "Validation error",
//         details: validationResult.error.details,
//       });
//     }
//     return next();
//   };
// };

// this code handles noraml email instead of FCAIStudentEmail

// validation.middleware.js
import joi from "joi";
import { genderTypes } from "../DB/model/User.model.js";
import { Types } from "mongoose";

export const isValidObjectId = (value, helper) => {
  return Types.ObjectId.isValid(value) ? true : helper.message("Invalid object Id");
};

export const generalFields = {
  name: joi.string().min(3).max(50).trim().required(),
  gender: joi.string().valid(...Object.values(genderTypes)).optional(),
  email: joi.string()
    .email({ tlds: { allow: false } }) // Updated email validation
    .required()
    .messages({
      "string.email": "Please enter a valid email address"
    }),
  level: joi.number().valid(1, 2, 3, 4).optional(),
  password: joi.string()
    .required()
    .pattern(new RegExp(/^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[#&<>@\"~;$^%{}?])(?=.*[a-zA-Z]).{8,}$/))
    .messages({
      "string.pattern.base": "Password must be at least 8 characters, include 1 uppercase, 1 lowercase, 1 number, and 1 special character."
    }),
  confirmPassword: joi.string()
    .required()
    .valid(joi.ref("password"))
    .messages({
      "any.only": "Confirm password must match password"
    }),
  id: joi.string().custom(isValidObjectId),
};

export const validation = (Schema) => {
  return (req, res, next) => {
    const inputs = { ...req.body, ...req.params, ...req.query };
    const validationResult = Schema.validate(inputs, { abortEarly: false });
    if (validationResult.error) {
      return res.status(400).json({
        message: "Validation error",
        details: validationResult.error.details,
      });
    }
    return next();
  };
};