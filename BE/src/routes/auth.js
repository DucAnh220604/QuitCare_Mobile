import express from "express";
import { register, login, getProfile } from "../controllers/authController.js";
import {
  validateRegister,
  validateLogin,
  handleValidationErrors,
} from "../middleware/validation.js";
import auth from "../middleware/auth.js";

const router = express.Router();

router.post("/register", validateRegister, handleValidationErrors, register);

router.post("/login", validateLogin, handleValidationErrors, login);

router.get("/profile", auth, getProfile);

export default router;
