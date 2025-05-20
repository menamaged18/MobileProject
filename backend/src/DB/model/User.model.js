// user.model.js
import mongoose, { Schema, model } from "mongoose";
import { Counter } from './counter.model.js';

export const genderTypes = { male: "male", female: "female" };

const userSchema = new Schema(
  {
    // User ID (Mandatory)
    userID: { 
      type: Number, 
      unique: true 
    },  

    name: {
      type: String,
      required: true,
      minlength: 3,
      maxlength: 50,
      trim: true,
    },

    gender: {
      type: String,
      enum: Object.values(genderTypes),
      default: null,
    },

    // Email (Mandatory)
    email: {
      type: String,
      required: true,
      unique: true,
    },

    // Level (Optional - Only 1, 2, 3, or 4)
    level: {
      type: Number,
      enum: [1, 2, 3, 4],
      default: null,
    },

    // Password (Mandatory - At least 8 characters with 1 number)
    password: {
      type: String,
      required: true,
      minlength: 8,
    },

    imageProfile: {
      type: String,
      default: null
    },
    imageProfileData: {  // For storing binary data if needed
      type: Buffer,
      select: false
    },

    // favourite stores
    favoriteStores: [{ type: Schema.Types.ObjectId, ref: 'Store' }]
  },

  { timestamps: true } // Automatically adds createdAt and updatedAt
);


// pre-save hook for auto-increament id
userSchema.pre('save', async function(next) {
  if (this.isNew) {
    const counter = await Counter.findByIdAndUpdate(
      'userID',
      { $inc: { seq: 1 } },
      { new: true, upsert: true }
    );
    this.userID = counter.seq;
  }
  next();
});


export const userModel = mongoose.models.User || model("User", userSchema);
