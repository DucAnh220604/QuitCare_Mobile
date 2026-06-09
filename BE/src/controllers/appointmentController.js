import Appointment from "../models/Appointment.js";
import User from "../models/User.js";
import { createMeetLink } from "../utils/googleCalendarService.js";

// @desc    Book an appointment
// @route   POST /api/appointments
// @access  Private
export const bookAppointment = async (req, res) => {
  try {
    const { startTime } = req.body;

    if (!startTime) {
      return res.status(400).json({ success: false, message: "Vui lòng cung cấp thời gian bắt đầu" });
    }

    const start = new Date(startTime);
    // Thời lượng cuộc gọi 45 phút
    const end = new Date(start.getTime() + 45 * 60000);

    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ success: false, message: "Không tìm thấy người dùng" });

    if (user.membership?.type !== "199k") {
      return res.status(403).json({ success: false, message: "Tính năng này chỉ dành cho tài khoản VIP" });
    }

    const { totalAllowed, callsUsed, expireAt } = user.membership.doctorCalls;

    if (callsUsed >= totalAllowed) {
      return res.status(403).json({ success: false, message: "Bạn đã sử dụng hết số lượt tư vấn" });
    }

    if (expireAt && new Date() > new Date(expireAt)) {
      return res.status(403).json({ success: false, message: "Đặc quyền tư vấn của bạn đã hết hạn (chỉ khả dụng trong 1 tháng đầu)" });
    }

    // Tạo link Meet
    const meetLink = await createMeetLink(start, end, `Tư vấn cai thuốc lá - ${user.fullname}`);

    // Tạo lịch
    const appointment = await Appointment.create({
      userId: user._id,
      startTime: start,
      endTime: end,
      meetLink: meetLink,
    });

    // Trừ 1 lượt gọi
    user.membership.doctorCalls.callsUsed += 1;
    await user.save();

    res.status(201).json({
      success: true,
      data: appointment,
      message: "Đặt lịch thành công"
    });
  } catch (error) {
    console.error("Lỗi khi đặt lịch:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get user's appointments
// @route   GET /api/appointments
// @access  Private
export const getAppointments = async (req, res) => {
  try {
    const appointments = await Appointment.find({ userId: req.user.id }).sort({ startTime: -1 });
    res.status(200).json({
      success: true,
      data: appointments,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get booked slots for a specific date
// @route   GET /api/appointments/booked-slots
// @access  Private
export const getBookedSlots = async (req, res) => {
  try {
    const { date } = req.query; // format: YYYY-MM-DD
    if (!date) {
      return res.status(400).json({ success: false, message: "Vui lòng cung cấp ngày" });
    }

    // Start of day and end of day
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    // Get all appointments in this day, regardless of user (doctor is busy)
    const appointments = await Appointment.find({
      startTime: {
        $gte: startOfDay,
        $lte: endOfDay,
      },
      status: { $ne: "cancelled" }
    });

    const bookedTimes = appointments.map(apt => apt.startTime.toISOString());

    res.status(200).json({
      success: true,
      data: bookedTimes,
    });
  } catch (error) {
    console.error("Lỗi lấy khung giờ:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};
