import mongoose from "mongoose";
import dns from "dns";
import { env } from "./env.js";

// Force Google DNS (8.8.8.8) để tránh DNS issue
dns.setServers(["8.8.8.8", "8.8.4.4"]);

async function connectDB() {
  try {
    await mongoose.connect(env.MONGODB_URI, {
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    });
    console.log("MongoDB connected");
  } catch (error) {
    console.error("MongoDB connection error:", error);
    process.exit(1);
  }
}

mongoose.connection.on("disconnected", () => {
  console.warn("MongoDB disconnected");
});

export default connectDB;
