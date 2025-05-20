// success.response.js
export const successRespone = ({res, statusCode=200, message="Done", data={}}={})=>{
    return res.status(statusCode).json({message, data})
}


export class SuccessResponse {
    constructor(res, message, data = {}, statusCode = 200) {
      res.status(statusCode).json({
        success: true,
        message,
        data,
      });
    }
  }