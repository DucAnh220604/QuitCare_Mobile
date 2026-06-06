import User from "../models/User.js";
import crypto from "crypto";

// @desc    Get membership packages
// @route   GET /api/membership/packages
// @access  Public
const getPackages = async (req, res) => {
  try {
    const packages = [
      {
        id: "99k",
        name: "Gói Cơ Bản",
        price: 99000,
        currency: "VND",
        features: [
          "Xem thống kê chi tiết",
          "Xây dựng kế hoạch đề xuất",
          "Xây dựng kế hoạch tự tạo",
        ],
        duration: "Vô hạn",
      },
      {
        id: "199k",
        name: "Gói Premium",
        price: 199000,
        currency: "VND",
        features: [
          "Xem thống kê chi tiết",
          "Xây dựng kế hoạch đề xuất",
          "Xây dựng kế hoạch tự tạo",
          "Video call (Google Meet)",
        ],
        duration: "Vô hạn",
      },
    ];

    res.status(200).json({
      success: true,
      data: packages,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Register membership
// @route   POST /api/membership/register
// @access  Private
const registerMembership = async (req, res) => {
  try {
    const { packageId } = req.body;

    if (!packageId || !["99k", "199k"].includes(packageId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid package ID",
      });
    }

    // Generate mock transaction ID
    const transactionId = `TXN_${Date.now()}_${crypto.randomBytes(4).toString("hex").toUpperCase()}`;

    let doctorCallsData = {
      totalAllowed: 0,
      callsUsed: 0,
      expireAt: null,
    };

    if (packageId === "199k") {
      doctorCallsData.totalAllowed = 4;
      const expireDate = new Date();
      expireDate.setDate(expireDate.getDate() + 30);
      doctorCallsData.expireAt = expireDate;
    }

    const user = await User.findByIdAndUpdate(
      req.user.id,
      {
        "membership.type": packageId,
        "membership.status": "active",
        "membership.startDate": new Date(),
        "membership.transactionId": transactionId,
        "membership.doctorCalls": doctorCallsData,
      },
      { new: true, runValidators: false }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Membership registered successfully",
      data: {
        user: {
          _id: user._id,
          fullname: user.fullname,
          email: user.email,
          membership: user.membership,
        },
        transaction: {
          id: transactionId,
          packageId,
          amount: packageId === "99k" ? 99000 : 199000,
          currency: "VND",
          timestamp: new Date(),
        },
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Get current user membership
// @route   GET /api/membership/current
// @access  Private
const getCurrentMembership = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    res.status(200).json({
      success: true,
      data: user.membership,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export { getPackages, registerMembership, getCurrentMembership };
