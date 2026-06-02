import express from "express";
import { logDailyProgress, getProgressStats, getHistory, forceSimulate, completePlan } from "../controllers/progressController.js";
import auth from "../middleware/auth.js";

const router = express.Router();

router.post("/checkin", auth, logDailyProgress);
router.get("/stats", auth, getProgressStats);
router.get("/history", auth, getHistory);
router.post("/force-simulate", auth, forceSimulate);
router.post("/complete-plan", auth, completePlan);

export default router;
