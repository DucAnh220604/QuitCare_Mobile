import QuitPlan from "../models/QuitPlan.js";
import User from "../models/User.js";

const addWeeks = (date, weeks) => {
  const result = new Date(date);
  result.setDate(result.getDate() + weeks * 7);
  return result;
};

const getAddictionLevel = (cigarettesPerDay) => {
  if (cigarettesPerDay <= 10) return "Thấp";
  if (cigarettesPerDay <= 20) return "Trung bình";
  return "Cao";
};

// @desc    Generate suggested quit plan (not saved) based on user profile
// @route   GET /api/quit-plan/generate
// @access  Private
export const generateSuggestedPlan = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    const profile = user?.smokingProfile;

    if (!profile || !profile.cigarettesPerDay) {
      return res.status(400).json({
        success: false,
        message: "Chưa có thông tin hút thuốc để tạo kế hoạch đề xuất",
      });
    }

    const cigs = profile.cigarettesPerDay;
    const startDate = profile.quitDate ? new Date(profile.quitDate) : new Date();
    startDate.setHours(0, 0, 0, 0);

    const addictionLevel = getAddictionLevel(cigs);

    // 5 stages × 4 weeks each = 20 weeks total
    const stageConfigs = [
      { weeks: "1 - 4", weekStart: 0, weekEnd: 4, cigs: cigs },
      { weeks: "5 - 8", weekStart: 4, weekEnd: 8, cigs: Math.ceil(cigs / 2) },
      { weeks: "9 - 12", weekStart: 8, weekEnd: 12, cigs: Math.ceil(cigs / 4) },
      { weeks: "13 - 16", weekStart: 12, weekEnd: 16, cigs: 1 },
      { weeks: "17 - 20", weekStart: 16, weekEnd: 20, cigs: 0 },
    ];

    // endDate of each stage = nextStageStart - 1 day (so stages are contiguous with no gaps)
    const addDays = (date, days) => {
      const result = new Date(date);
      result.setDate(result.getDate() + days);
      return result;
    };

    const stages = stageConfigs.map((cfg, idx) => ({
      stageName: `Giai đoạn ${idx + 1}`,
      weekRange: `Tuần ${cfg.weeks}`,
      startDate: addWeeks(startDate, cfg.weekStart),
      endDate: addDays(addWeeks(startDate, cfg.weekEnd), -1),
      cigarettesPerDay: cfg.cigs,
    }));

    const lastStageEnd = addDays(addWeeks(startDate, 20), -1);

    res.status(200).json({
      success: true,
      data: {
        type: "suggested",
        addictionLevel,
        baselineCigarettes: cigs,
        stages,
        overallStartDate: startDate,
        overallEndDate: lastStageEnd,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Confirm and save a quit plan (locks it as immutable)
// @route   POST /api/quit-plan/confirm
// @access  Private
export const confirmPlan = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: "Người dùng không tồn tại" });
    }

    // Reject if user already has an active confirmed plan
    const existing = await QuitPlan.findOne({ userId: req.user.id, isConfirmed: true });
    if (existing) {
      return res.status(400).json({
        success: false,
        message: "Bạn đã có kế hoạch đang hoạt động. Không thể tạo kế hoạch mới.",
      });
    }

    const { type, stages, overallStartDate, overallEndDate, addictionLevel, baselineCigarettes } = req.body;

    if (!type || !stages || !Array.isArray(stages) || stages.length === 0) {
      return res.status(400).json({ success: false, message: "Dữ liệu kế hoạch không hợp lệ" });
    }

    if (!overallStartDate || !overallEndDate) {
      return res.status(400).json({ success: false, message: "Thiếu ngày bắt đầu hoặc kết thúc" });
    }

    const plan = await QuitPlan.create({
      userId: req.user.id,
      type,
      addictionLevel,
      baselineCigarettes,
      stages,
      overallStartDate: new Date(overallStartDate),
      overallEndDate: new Date(overallEndDate),
      isConfirmed: true,
      confirmedAt: new Date(),
    });

    // Link plan to user
    user.smokingProfile = user.smokingProfile || {};
    user.smokingProfile.activeQuitPlanId = plan._id;
    await user.save();

    res.status(201).json({ success: true, message: "Kế hoạch đã được xác nhận và lưu thành công", data: plan });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get current confirmed quit plan
// @route   GET /api/quit-plan/current
// @access  Private
export const getCurrentPlan = async (req, res) => {
  try {
    const plan = await QuitPlan.findOne({ userId: req.user.id, isConfirmed: true }).sort({ confirmedAt: -1 });

    if (!plan) {
      return res.status(404).json({ success: false, message: "Chưa có kế hoạch cai thuốc nào được xác nhận" });
    }

    res.status(200).json({ success: true, data: plan });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
