import mongoose from "mongoose";

const stageSchema = new mongoose.Schema(
  {
    stageName: { type: String, required: true },
    weekRange: { type: String, required: true },
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    cigarettesPerDay: { type: Number, required: true, min: 0 },
  },
  { _id: false }
);

const quitPlanSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    type: {
      type: String,
      enum: ["suggested", "custom"],
      required: true,
    },
    addictionLevel: {
      type: String,
      enum: ["Thấp", "Trung bình", "Cao"],
    },
    baselineCigarettes: { type: Number, default: 0 },
    stages: [stageSchema],
    overallStartDate: { type: Date, required: true },
    overallEndDate: { type: Date, required: true },
    isConfirmed: { type: Boolean, default: false },
    confirmedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

const QuitPlan = mongoose.model("QuitPlan", quitPlanSchema);

export default QuitPlan;
