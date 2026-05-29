import { body, validationResult } from "express-validator";

const validateRegister = [
  body("fullname")
    .trim()
    .notEmpty()
    .withMessage("Fullname is required")
    .isLength({ max: 50 })
    .withMessage("Fullname cannot exceed 50 characters"),
  body("email")
    .trim()
    .isEmail()
    .withMessage("Please provide a valid email")
    .normalizeEmail(),
  body("password")
    .isLength({ min: 8 })
    .withMessage("Password must be at least 8 characters long"),
  body("phone").trim().notEmpty().withMessage("Phone number is required"),
];

const validateLogin = [
  body("email")
    .trim()
    .isEmail()
    .withMessage("Please provide a valid email")
    .normalizeEmail(),
  body("password").notEmpty().withMessage("Password is required"),
];

const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: "Validation failed",
      errors: errors.array().map((err) => ({
        field: err.param,
        message: err.msg,
      })),
    });
  }
  next();
};

export { validateRegister, validateLogin, handleValidationErrors };
