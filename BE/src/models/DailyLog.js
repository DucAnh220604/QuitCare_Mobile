import mongoose from "mongoose";

const dailyLogSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    date: {
      type: Date,
      required: true,
    },
    cigarettesSmoked: {
      type: Number,
      required: true,
      default: 0,
    },
    cravingLevel: {
      type: String,
      enum: ["Không thèm", "Thèm nhẹ", "Thèm nhiều", ""],
      default: "",
    },
    mood: {
      type: String,
      enum: ["Tốt", "Bình thường", "Tệ", ""],
      default: "",
    },
    symptoms: [
      {
        type: String,
      },
    ],
    note: {
      type: String,
      default: "",
    },
    isMissedDay: {
      type: Boolean,
      default: false, // Flag to identify auto-generated failed days (missed days)
    }
  },
  { timestamps: true }
);

// Ensure only 1 log per user per day
dailyLogSchema.index({ userId: 1, date: 1 }, { unique: true });

const DailyLog = mongoose.model("DailyLog", dailyLogSchema);

export default DailyLog;
