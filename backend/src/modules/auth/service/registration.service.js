// auth/service/registration.service.js
import { asyncHandler } from "../../../utilis/response/error.response.js";
import { userModel } from "../../../DB/model/User.model.js";
import { generateHash } from "../../../utilis/security/hash.security.js";
import { successRespone } from "../../../utilis/response/success.response.js";
import * as dbService from "../../../DB/db.service.js";

export const signup = asyncHandler(async (req, res, next) => {
  const { name, gender, email, level, password, confirmPassword } = req.body;

  if (await dbService.findOne({ model: userModel, filter: { email } })) {
    return next(new Error("Email already exists", { cause: 409 }));
  }

  const hashedPassword = generateHash({ plainText: password });

  const user = await dbService.create({
    model: userModel,
    data: {
      name,
      gender,
      email,
      level,
      password: hashedPassword,
    },
  });

  return successRespone({
    res,
    message: "Signup successfully",
    statusCode: 201,
  });
});
