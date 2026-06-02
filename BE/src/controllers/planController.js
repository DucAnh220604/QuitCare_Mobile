import Plan from "../models/Plan.js";
import User from "../models/User.js";

// @desc    Seed basic medical plans
// @route   POST /api/plans/seed
// @access  Public (for development)
export const seedPlans = async (req, res) => {
  try {
    const plansCount = await Plan.countDocuments();
    if (plansCount > 0) {
      // Clear existing to re-seed
      await Plan.deleteMany({});
    }

    const basicPlans = [
      {
        name: "Cai thuốc đột ngột (Cold Turkey)",
        shortDescription: "Ngừng hút thuốc hoàn toàn ngay lập tức.",
        description: "Phương pháp cai thuốc lá đột ngột yêu cầu bạn phải dừng hút thuốc hoàn toàn và vĩnh viễn vào ngày đã định. Theo Hiệp hội Ung thư Hoa Kỳ (ACS), phương pháp này phù hợp nhất với những người có quyết tâm rất cao hoặc mức độ phụ thuộc nicotine thấp.",
        targetAudience: "Người hút dưới 10 điếu/ngày, mức độ thèm thuốc buổi sáng thấp.",
        durationDays: 30,
        difficulty: "Khó",
        dailyTasks: [
          "Tránh xa môi trường có khói thuốc",
          "Uống 2 lít nước mỗi ngày",
          "Nhai kẹo cao su không đường khi thèm thuốc",
          "Tập thể dục 30 phút",
        ],
        scoringRules: {
          cigarettesPerDayWeight: 1, // 0-10 -> 0-10 pts
          smokingYearsWeight: 0.5,
          morningCravingWeights: {
            "Thấp": 0,
            "Trung bình": 15,
            "Cao": 30,
          },
          // Cold turkey is best for low scores (low dependence)
          idealScoreRange: { min: 0, max: 20 },
        },
      },
      {
        name: "Giảm dần bằng Nicotine thay thế (NRT)",
        shortDescription: "Sử dụng các sản phẩm hỗ trợ chứa nicotine liều thấp.",
        description: "Sử dụng kẹo cao su, miếng dán, hoặc ống hít nicotine (NRT) giúp giảm bớt các triệu chứng cai nghiện bằng cách cung cấp một lượng nhỏ nicotine không chứa các hóa chất độc hại trong khói thuốc. Phương pháp này được WHO và CDC khuyên dùng cho người có mức độ nghiện trung bình đến cao.",
        targetAudience: "Người hút 10-20 điếu/ngày, mức độ thèm thuốc trung bình đến cao.",
        durationDays: 60,
        difficulty: "Trung bình",
        dailyTasks: [
          "Sử dụng miếng dán Nicotine vào buổi sáng",
          "Ghi chú lại mỗi lần thèm thuốc",
          "Thực hiện bài tập hít thở sâu",
        ],
        scoringRules: {
          cigarettesPerDayWeight: 1, // 10-20 -> 10-20 pts
          smokingYearsWeight: 0.5,
          morningCravingWeights: {
            "Thấp": 0,
            "Trung bình": 15,
            "Cao": 30,
          },
          // NRT is best for medium-high dependence
          idealScoreRange: { min: 21, max: 45 },
        },
      },
      {
        name: "Cai thuốc giảm dần có kế hoạch (Tapering)",
        shortDescription: "Giảm số lượng điếu thuốc mỗi ngày một cách từ từ.",
        description: "Phương pháp giảm dần (Tapering) bao gồm việc đặt mục tiêu giảm dần số lượng điếu thuốc hút mỗi ngày cho đến khi bạn có thể ngừng hoàn toàn. Phương pháp này thường kéo dài và đòi hỏi kỷ luật cao, phù hợp với người hút thuốc lâu năm hoặc rất nặng khó có thể bỏ ngay lập tức.",
        targetAudience: "Người hút trên 20 điếu/ngày, hút thuốc nhiều năm.",
        durationDays: 90,
        difficulty: "Khó",
        dailyTasks: [
          "Ghi chép số điếu thuốc đã hút",
          "Trì hoãn cơn thèm thuốc 15 phút",
          "Tìm người hỗ trợ (buddy) để báo cáo tiến độ",
        ],
        scoringRules: {
          cigarettesPerDayWeight: 1, // > 20 -> > 20 pts
          smokingYearsWeight: 0.5,
          morningCravingWeights: {
            "Thấp": 0,
            "Trung bình": 15,
            "Cao": 30,
          },
          // Tapering is best for high dependence
          idealScoreRange: { min: 46, max: 999 },
        },
      }
    ];

    const plans = await Plan.insertMany(basicPlans);
    res.status(200).json({ success: true, count: plans.length, plans });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Select a plan for user
// @route   POST /api/plans/select
// @access  Private
export const selectPlan = async (req, res) => {
  try {
    const { planId } = req.body;
    
    if (!planId) {
      return res.status(400).json({ success: false, message: "Vui lòng chọn kế hoạch" });
    }

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    // Verify if plan exists
    const plan = await Plan.findById(planId);
    if (!plan) {
      return res.status(404).json({ success: false, message: "Kế hoạch không tồn tại" });
    }

    user.smokingProfile = user.smokingProfile || {};
    user.smokingProfile.currentPlan = planId;
    await user.save();

    res.status(200).json({ success: true, message: "Đã lưu kế hoạch thành công", plan });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get current user plan
// @route   GET /api/plans/my-plan
// @access  Private
export const getMyPlan = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).populate("smokingProfile.currentPlan");
    if (!user || !user.smokingProfile || !user.smokingProfile.currentPlan) {
      return res.status(404).json({ success: false, message: "Chưa có kế hoạch nào được chọn" });
    }
    res.status(200).json({ success: true, plan: user.smokingProfile.currentPlan });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get recommended plan based on user smoking profile
// @route   GET /api/plans/recommend
// @access  Private
export const getRecommendedPlan = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    const profile = user.smokingProfile;

    if (!profile || profile.cigarettesPerDay === 0) {
      return res.status(400).json({
        success: false,
        message: "Chưa có thông tin hút thuốc để gợi ý kế hoạch",
      });
    }

    // Tính điểm phụ thuộc (Dependence Score)
    const cigs = profile.cigarettesPerDay || 0;
    const years = profile.smokingYears || 0;
    const morningCraving = profile.morningCravingLevel || "Thấp";

    const allPlans = await Plan.find();
    
    // Evaluate scores for each plan
    let bestPlan = null;
    let otherPlans = [];
    
    const plansWithScores = allPlans.map(plan => {
      const rules = plan.scoringRules;
      const cravingScore = rules.morningCravingWeights[morningCraving] || 0;
      
      const totalScore = (cigs * rules.cigarettesPerDayWeight) + (years * rules.smokingYearsWeight) + cravingScore;
      
      // Calculate how far the score is from the ideal range center
      const rangeCenter = (rules.idealScoreRange.max >= 999) ? (rules.idealScoreRange.min + 20) : ((rules.idealScoreRange.min + rules.idealScoreRange.max) / 2);
      const diff = Math.abs(totalScore - rangeCenter);

      return {
        plan,
        totalScore,
        diff,
        isIdeal: totalScore >= rules.idealScoreRange.min && totalScore <= rules.idealScoreRange.max,
      };
    });

    // Sort by being in ideal range first, then by closest distance to center
    plansWithScores.sort((a, b) => {
      if (a.isIdeal && !b.isIdeal) return -1;
      if (!a.isIdeal && b.isIdeal) return 1;
      return a.diff - b.diff;
    });

    if (plansWithScores.length > 0) {
      bestPlan = plansWithScores[0].plan;
      otherPlans = plansWithScores.slice(1).map(p => p.plan);
    }

    res.status(200).json({
      success: true,
      data: {
        recommendedPlan: bestPlan,
        otherOptions: otherPlans,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
