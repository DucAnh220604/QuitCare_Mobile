import DailyLog from "../models/DailyLog.js";
import User from "../models/User.js";
import Plan from "../models/Plan.js";

// Helper: Normalize date to Midnight UTC
const getMidnight = (dateString) => {
  const d = new Date(dateString);
  d.setUTCHours(0, 0, 0, 0);
  return d;
};

// @desc    Log daily progress
// @route   POST /api/progress/checkin
// @access  Private
export const logDailyProgress = async (req, res) => {
  try {
    const { cigarettesSmoked, cravingLevel, mood, symptoms, note, date } = req.body;
    const logDate = getMidnight(date || new Date());

    const existingLog = await DailyLog.findOne({
      userId: req.user.id,
      date: logDate,
    });

    if (existingLog) {
      existingLog.cigarettesSmoked = cigarettesSmoked;
      existingLog.cravingLevel = cravingLevel;
      existingLog.mood = mood;
      existingLog.symptoms = symptoms;
      existingLog.note = note;
      existingLog.isMissedDay = false; // user manually updated it
      await existingLog.save();
      return res.status(200).json({ success: true, data: existingLog });
    } else {
      const newLog = await DailyLog.create({
        userId: req.user.id,
        date: logDate,
        cigarettesSmoked,
        cravingLevel,
        mood,
        symptoms,
        note,
      });
      return res.status(201).json({ success: true, data: newLog });
    }
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get progress stats (calculates streak, backfills missed days)
// @route   GET /api/progress/stats
// @access  Private
export const getProgressStats = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).populate("smokingProfile.currentPlan");
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }
    const profile = user.smokingProfile;

    if (!profile || !profile.quitDate) {
      return res.status(400).json({
        success: false,
        message: "Chưa có ngày bắt đầu cai thuốc",
      });
    }

    const quitDate = getMidnight(profile.quitDate);
    const today = getMidnight(new Date());

    // 1. Backfill missed days from quitDate to yesterday
    const allExistingLogs = await DailyLog.find({ userId: req.user.id }).sort({ date: 1 });
    const logDatesMap = new Map();
    allExistingLogs.forEach(log => {
      logDatesMap.set(log.date.getTime(), log);
    });

    const newLogs = [];
    let currentDate = new Date(quitDate);
    
    // We only backfill up to yesterday automatically. Today requires manual check-in.
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    while (currentDate <= yesterday) {
      if (!logDatesMap.has(currentDate.getTime())) {
        newLogs.push({
          userId: req.user.id,
          date: new Date(currentDate),
          cigarettesSmoked: profile.cigarettesPerDay, // Assume failed if missed
          isMissedDay: true,
          note: "Bỏ lỡ ghi nhận (Tự động tạo)",
        });
      }
      currentDate.setDate(currentDate.getDate() + 1);
    }

    if (newLogs.length > 0) {
      await DailyLog.insertMany(newLogs);
    }

    // 2. Fetch fresh logs after backfill
    const fullLogs = await DailyLog.find({
      userId: req.user.id,
      date: { $gte: quitDate, $lte: today }
    }).sort({ date: 1 });

    let streak = 0;
    let totalAvoided = 0;
    let hasCheckedInToday = false;

    fullLogs.forEach(log => {
      // Calculate Avoided
      const avoidedToday = Math.max(0, profile.cigarettesPerDay - log.cigarettesSmoked);
      totalAvoided += avoidedToday;

      // Calculate Streak (Smoke-free days)
      if (log.cigarettesSmoked === 0 && !log.isMissedDay) {
        streak++;
      } else {
        streak = 0; // Reset streak on any day with smoking or missed day
      }

      if (log.date.getTime() === today.getTime() && !log.isMissedDay) {
        hasCheckedInToday = true;
      }
    });
    
    // If user hasn't checked in today, but yesterday they had a streak, the streak is currently preserved (until tomorrow when today becomes a missed day).
    
    const price = profile.pricePerCigarette || 1000;
    const moneySaved = totalAvoided * price;

    const durationDays = profile.currentPlan ? profile.currentPlan.durationDays : 0;

    res.status(200).json({
      success: true,
      data: {
        streak,
        moneySaved,
        totalAvoided,
        hasCheckedInToday,
        logsCount: fullLogs.length,
        durationDays,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get check-in history
// @route   GET /api/progress/history
// @access  Private
export const getHistory = async (req, res) => {
  try {
    const logs = await DailyLog.find({ userId: req.user.id }).sort({ date: -1 });
    res.status(200).json({ success: true, data: logs });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Force simulate full plan progress
// @route   POST /api/progress/force-simulate
// @access  Private
export const forceSimulate = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).populate("smokingProfile.currentPlan");
    const profile = user.smokingProfile;

    if (!profile || !profile.currentPlan) {
      return res.status(400).json({
        success: false,
        message: "Người dùng chưa chọn kế hoạch cai thuốc",
      });
    }

    const durationDays = profile.currentPlan.durationDays || 30;

    // Set quitDate to (durationDays) days ago
    const newQuitDate = getMidnight(new Date());
    newQuitDate.setDate(newQuitDate.getDate() - durationDays + 1);
    
    user.smokingProfile.quitDate = newQuitDate;
    await user.save();

    // Delete existing logs
    await DailyLog.deleteMany({ userId: req.user.id });

    // Generate random logs
    const newLogs = [];
    const today = getMidnight(new Date());
    let currentDate = new Date(newQuitDate);

    while (currentDate <= today) {
      // 85% chance of 0 cigarettes, 15% chance of 1-3 cigarettes
      const isSuccess = Math.random() < 0.85;
      const smoked = isSuccess ? 0 : Math.floor(Math.random() * 3) + 1;

      newLogs.push({
        userId: req.user.id,
        date: new Date(currentDate),
        cigarettesSmoked: Math.min(smoked, profile.cigarettesPerDay || 10),
        cravingLevel: isSuccess ? "Không thèm" : "Thèm nhiều",
        mood: isSuccess ? "Tốt" : "Tệ",
        note: isSuccess ? "Giả lập: Ngày thành công" : "Giả lập: Trượt ngã",
        isMissedDay: false,
      });

      currentDate.setDate(currentDate.getDate() + 1);
    }

    await DailyLog.insertMany(newLogs);

    res.status(200).json({
      success: true,
      message: `Đã giả lập thành công ${newLogs.length} ngày!`,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Complete current plan and archive it
// @route   POST /api/progress/complete-plan
// @access  Private
export const completePlan = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).populate("smokingProfile.currentPlan");
    const profile = user.smokingProfile;

    if (!profile || !profile.currentPlan) {
      return res.status(400).json({ success: false, message: "Không có kế hoạch nào đang chạy" });
    }

    const currentPlan = profile.currentPlan;
    const today = getMidnight(new Date());
    
    // Calculate final stats (we need total avoided and streak)
    const logs = await DailyLog.find({ userId: req.user.id });
    
    let totalAvoided = 0;
    logs.forEach(log => {
      const avoided = Math.max(0, profile.cigarettesPerDay - log.cigarettesSmoked);
      totalAvoided += avoided;
    });
    
    const price = profile.pricePerCigarette || 1000;
    const moneySaved = totalAvoided * price;

    // Push to pastPlans
    profile.pastPlans = profile.pastPlans || [];
    profile.pastPlans.push({
      planId: currentPlan._id,
      planName: currentPlan.name,
      startDate: profile.quitDate,
      endDate: today,
      moneySaved: moneySaved,
      daysStreak: logs.length,
      cigarettesAvoided: totalAvoided,
    });

    // Reset currentPlan and reset quitDate to today for the next plan
    profile.currentPlan = null;
    profile.quitDate = today;
    await user.save();

    // Delete old logs so they don't carry over to the next plan!
    await DailyLog.deleteMany({ userId: req.user.id });

    res.status(200).json({
      success: true,
      message: "Chúc mừng bạn đã hoàn thành Kế hoạch cai thuốc!",
      pastPlans: profile.pastPlans
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
