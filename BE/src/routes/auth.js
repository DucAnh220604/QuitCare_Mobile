import express from "express";
import {
  register,
  login,
  getProfile,
  updateProfile,
  uploadAvatar,
  changePassword,
} from "../controllers/authController.js";
import {
  validateRegister,
  validateLogin,
  handleValidationErrors,
} from "../middleware/validation.js";
import auth from "../middleware/auth.js";
import upload from "../middleware/upload.js";

const router = express.Router();

router.post("/register", validateRegister, handleValidationErrors, register);

router.post("/login", validateLogin, handleValidationErrors, login);

router.get("/profile", auth, getProfile);
router.put("/profile", auth, updateProfile);
router.post("/avatar", auth, upload.single("avatar"), uploadAvatar);
router.put("/change-password", auth, changePassword);

export default router;
