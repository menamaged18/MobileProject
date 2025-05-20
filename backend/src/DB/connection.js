// connection.js
import mongoose from "mongoose";

const connectDB = async () => {
  return await mongoose
    .connect(process.env.DB_URI)
    .then((res) => {
        console.log(`DB Connected`);
    })
    .catch(error=>{
        console.error("Fail to connect on DB");
    });
};

export default connectDB;