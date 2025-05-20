import jwt from "jsonwebtoken";
import { userModel } from "../../DB/model/User.model.js";
import * as dbService from "../../DB/db.service.js";
import mongoose from "mongoose";


export const tokenTypes = {
    access: "access",
    refresh: "refresh",
  };
  
  export const decodedToken = async ({ authorization = "", next = {} } = {}) => {
    if (!authorization) {
      return next(new Error("Missing token", { cause: 400 }));
    }
  
    const [bearer, token] = authorization.split(" ");
    if (bearer !== "Bearer" || !token) {
      return next(new Error("Invalid token format", { cause: 400 }));
    }
  
    try {
      const decoded = jwt.verify(token, process.env.USER_ACCESS_TOKEN);
  
  
      if (!decoded?.id) {
        return next(new Error("Invalid token payload", { cause: 401 }));
      }
  
      const user = await dbService.findOne({
        model: userModel,
        filter: { _id: new mongoose.Types.ObjectId(decoded.id) },
      });
    
      if (!user) {
        return next(new Error("User not found", { cause: 404 }));
      }
  
      return user;
    } catch (error) {
      return next(new Error("Invalid or expired token", { cause: 401 }));
    }
  };
  

export const generateToken = ({payload={}, signature = process.env.USER_ACCESS_TOKEN, expiresIn=process.env.EXPIRES_IN}={})=>{
    const token = jwt.sign(payload, signature, {expiresIn: parseInt(expiresIn)});
    return token;
}

export const verifyToken = ({token, signature = process.env.USER_ACCESS_TOKEN}={})=>{
    const decoded = jwt.verify(token, signature);
    return decoded;
}