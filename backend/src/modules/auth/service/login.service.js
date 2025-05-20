import { asyncHandler } from "../../../utilis/response/error.response.js";
import {userModel} from "../../../DB/model/User.model.js";
import {compareHash} from "../../../utilis/security/hash.security.js";
import { successRespone } from "../../../utilis/response/success.response.js";
import * as dbService from "../../../DB/db.service.js";
import { generateToken } from "../../../utilis/security/token.security.js";

export const login = asyncHandler(async (req, res, next) => {
  const { email, password } = req.body;

  // const studentID = email.split("@")[0];
  const user = await dbService.findOne({ model: userModel, filter: { email } });

  if (!user) {
    return next(new Error("Invalid account or student ID mismatch", { cause: 404 }));
  }

  const isPasswordValid = compareHash({ plainText: password, hashValue: user.password });
  if (!isPasswordValid) {
    return next(new Error("Wrong password.", { cause: 400 }));
  }

  const accessToken = generateToken({
    payload: { id: user._id },
    signature: process.env.ADMIN_ACCESS_TOKEN

  });
  return successRespone({
    res,
    message: `Login successful` ,
    data: accessToken
  });
});
