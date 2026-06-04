import DailyLog from "../models/DailyLog.js";
import User from "../models/User.js";
import Plan from "../models/Plan.js";
import QuitPlan from "../models/QuitPlan.js";

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

    // Fetch active QuitPlan stage info if exists
    let quitPlanInfo = null;
    if (profile.activeQuitPlanId) {
      const quitPlan = await QuitPlan.findById(profile.activeQuitPlanId);
      if (quitPlan) {
        const now = new Date();
        let currentStage = null;
        let currentStageIndex = -1;
        for (let i = 0; i < quitPlan.stages.length; i++) {
          const stage = quitPlan.stages[i];
          if (now >= new Date(stage.startDate) && now <= new Date(stage.endDate)) {
            currentStage = stage;
            currentStageIndex = i;
            break;
          }
        }
        if (!currentStage && quitPlan.stages.length > 0) {
          if (now < new Date(quitPlan.stages[0].startDate)) {
            currentStage = quitPlan.stages[0];
            currentStageIndex = 0;
          } else {
            currentStage = quitPlan.stages[quitPlan.stages.length - 1];
            currentStageIndex = quitPlan.stages.length - 1;
          }
        }
        const overallStart = new Date(quitPlan.overallStartDate);
        const overallEnd = new Date(quitPlan.overallEndDate);
        const overallDays = Math.max(1, Math.round((overallEnd - overallStart) / 86400000));
        const elapsedDays = Math.max(0, Math.round((now - overallStart) / 86400000));
        quitPlanInfo = {
          type: quitPlan.type,
          addictionLevel: quitPlan.addictionLevel,
          currentStage,
          currentStageIndex,
          totalStages: quitPlan.stages.length,
          overallStartDate: quitPlan.overallStartDate,
          overallEndDate: quitPlan.overallEndDate,
          overallProgress: Math.min(1, elapsedDays / overallDays),
          durationDays: overallDays,
        };
      }
    }

    const durationDays = profile.currentPlan
      ? profile.currentPlan.durationDays
      : (quitPlanInfo?.durationDays ?? 0);

    res.status(200).json({
      success: true,
      data: {
        streak,
        moneySaved,
        totalAvoided,
        hasCheckedInToday,
        logsCount: fullLogs.length,
        durationDays,
        quitPlan: quitPlanInfo,
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

    if (!profile || (!profile.currentPlan && !profile.activeQuitPlanId)) {
      return res.status(400).json({
        success: false,
        message: "Người dùng chưa chọn kế hoạch cai thuốc",
      });
    }

    let durationDays = profile.currentPlan?.durationDays || 30;
    if (!profile.currentPlan && profile.activeQuitPlanId) {
      const qp = await QuitPlan.findById(profile.activeQuitPlanId);
      if (qp) {
        durationDays = Math.max(1, Math.round(
          (new Date(qp.overallEndDate) - new Date(qp.overallStartDate)) / 86400000
        ));
      }
    }

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

    if (!profile || (!profile.currentPlan && !profile.activeQuitPlanId)) {
      return res.status(400).json({ success: false, message: "Không có kế hoạch nào đang chạy" });
    }

    const today = getMidnight(new Date());

    // Resolve plan identity (predefined Plan or QuitPlan)
    let archivePlanId = null;
    let archivePlanName = "Kế hoạch cai thuốc";

    if (profile.currentPlan) {
      archivePlanId = profile.currentPlan._id;
      archivePlanName = profile.currentPlan.name;
    } else if (profile.activeQuitPlanId) {
      const qp = await QuitPlan.findById(profile.activeQuitPlanId);
      if (qp) {
        archivePlanName = qp.type === "suggested" ? "Kế hoạch đề xuất" : "Kế hoạch tự lập";
        // Deactivate quit plan
        qp.isConfirmed = false;
        await qp.save();
      }
    }

    // Calculate final stats
    const logs = await DailyLog.find({ userId: req.user.id });
    let totalAvoided = 0;
    logs.forEach(log => {
      totalAvoided += Math.max(0, profile.cigarettesPerDay - log.cigarettesSmoked);
    });
    const price = profile.pricePerCigarette || 1000;
    const moneySaved = totalAvoided * price;

    // Archive to pastPlans
    profile.pastPlans = profile.pastPlans || [];
    profile.pastPlans.push({
      ...(archivePlanId ? { planId: archivePlanId } : {}),
      planName: archivePlanName,
      startDate: profile.quitDate,
      endDate: today,
      moneySaved,
      daysStreak: logs.length,
      cigarettesAvoided: totalAvoided,
    });

    // Reset plan references and quit date
    profile.currentPlan = null;
    profile.activeQuitPlanId = null;
    profile.quitDate = today;
    await user.save();

    // Clear logs so they don't carry over to the next plan
    await DailyLog.deleteMany({ userId: req.user.id });

    res.status(200).json({
      success: true,
      message: "Chúc mừng bạn đã hoàn thành Kế hoạch cai thuốc!",
      pastPlans: profile.pastPlans,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
