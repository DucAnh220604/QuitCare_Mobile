import express from "express";
import {
  getPackages,
  registerMembership,
  getCurrentMembership,
} from "../controllers/membershipController.js";
import auth from "../middleware/auth.js";

const router = express.Router();

router.get("/packages", getPackages);
router.post("/register", auth, registerMembership);
router.get("/current", auth, getCurrentMembership);

export default router;
