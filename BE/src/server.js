import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import connectDB from "./config/db.js";
import authRoutes from "./routes/auth.js";
import membershipRoutes from "./routes/membership.js";
import planRoutes from "./routes/planRoutes.js";
import progressRoutes from "./routes/progressRoutes.js";
import quitPlanRoutes from "./routes/quitPlanRoutes.js";
import appointmentRoutes from "./routes/appointmentRoutes.js";
import communityRoutes from "./routes/communityRoutes.js";
import { runSeed } from "./controllers/communityController.js";

// Load env variables
dotenv.config();

const app = express();

// Connect to database
await connectDB();
await runSeed();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// API Routes
app.use("/api/auth", authRoutes);
app.use("/api/membership", membershipRoutes);
app.use("/api/plans", planRoutes);
app.use("/api/progress", progressRoutes);
app.use("/api/quit-plan", quitPlanRoutes);
app.use("/api/appointments", appointmentRoutes);
app.use("/api/community", communityRoutes);

// Health check
app.get("/api/health", (req, res) => {
  res.status(200).json({
    success: true,
    message: "Server is running",
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Route not found",
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  res.status(500).json({
    success: false,
    message: err.message,
  });
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
