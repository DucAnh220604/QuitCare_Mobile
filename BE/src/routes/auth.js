import express from "express";
import {
  register,
  login,
  getProfile,
  updateProfile,
} from "../controllers/authController.js";
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
router.put("/profile", auth, updateProfile);

export default router;
