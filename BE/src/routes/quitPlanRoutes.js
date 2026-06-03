import express from "express";
import { generateSuggestedPlan, confirmPlan, getCurrentPlan } from "../controllers/quitPlanController.js";
import auth from "../middleware/auth.js";

const router = express.Router();

router.get("/generate", auth, generateSuggestedPlan);
router.post("/confirm", auth, confirmPlan);
router.get("/current", auth, getCurrentPlan);

export default router;
