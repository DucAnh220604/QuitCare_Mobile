import express from "express";
import { seedPlans, getRecommendedPlan, selectPlan, getMyPlan } from "../controllers/planController.js";
import auth from "../middleware/auth.js";

const router = express.Router();

router.post("/seed", seedPlans);
router.get("/recommend", auth, getRecommendedPlan);
router.post("/select", auth, selectPlan);
router.get("/my-plan", auth, getMyPlan);

export default router;
