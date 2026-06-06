import express from "express";
import { bookAppointment, getAppointments, getBookedSlots } from "../controllers/appointmentController.js";
import auth from "../middleware/auth.js";

const router = express.Router();

router.post("/book", auth, bookAppointment);
router.get("/booked-slots", auth, getBookedSlots);
router.get("/", auth, getAppointments);

export default router;
