import mongoose from "mongoose";

const planSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
    },
    shortDescription: {
      type: String,
      required: true,
    },
    targetAudience: {
      type: String,
      required: true,
    },
    durationDays: {
      type: Number,
      required: true,
    },
    difficulty: {
      type: String,
      enum: ["Dễ", "Trung bình", "Khó"],
      required: true,
    },
    dailyTasks: [
      {
        type: String,
      },
    ],
    // For calculation
    scoringRules: {
      cigarettesPerDayWeight: { type: Number, default: 1 },
      smokingYearsWeight: { type: Number, default: 1 },
      morningCravingWeights: {
        "Thấp": { type: Number, default: 0 },
        "Trung bình": { type: Number, default: 5 },
        "Cao": { type: Number, default: 10 },
      },
      idealScoreRange: {
        min: { type: Number, required: true },
        max: { type: Number, required: true },
      },
    },
  },
  { timestamps: true }
);

const Plan = mongoose.model("Plan", planSchema);

export default Plan;
