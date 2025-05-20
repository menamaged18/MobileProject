import { asyncHandler } from "../utilis/response/error.response.js";
import { decodedToken } from "../utilis/security/token.security.js";


export const authentication = () => {
  return asyncHandler(async (req, res, next) => {
    const { authorization } = req.headers;
    req.user = await decodedToken({ authorization, next });
    return next();
  });
};

export const authorization = () => {
    return asyncHandler(async (req, res, next) => {

        if(!req.user.role){
            return next(new Error("Not authorized account", {cause: 403}));
        }
      return next();
    });
};