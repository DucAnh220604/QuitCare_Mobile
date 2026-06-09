import User from "../models/User.js";
import { generateToken } from "../config/jwt.js";
import cloudinary from "../config/cloudinary.js";

// @desc    Register user
// @route   POST /api/auth/register
// @access  Public
const register = async (req, res) => {
  try {
    const { fullname, email, password, phone } = req.body;

    // Check if user already exists
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({
        success: false,
        message: "Email này đã được đăng ký",
      });
    }

    // Create new user
    user = await User.create({
      fullname,
      email,
      password,
      phone,
    });

    // Generate token
    const token = generateToken(user._id);

    // Remove password from response
    user.password = undefined;

    res.status(201).json({
      success: true,
      message: "Đăng ký tài khoản thành công",
      data: {
        token,
        user: {
          _id: user._id,
          fullname: user.fullname,
          email: user.email,
          phone: user.phone,
          avatar: user.avatar,
          membership: user.membership,
          smokingProfile: user.smokingProfile,
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

// @desc    Login user
// @route   POST /api/auth/login
// @access  Public
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Check if email and password are provided
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng nhập email và mật khẩu",
      });
    }

    // Check for user
    const user = await User.findOne({ email }).select("+password");

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Email hoặc mật khẩu không đúng",
      });
    }

    // Check if password matches
    const isMatch = await user.matchPassword(password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Email hoặc mật khẩu không đúng",
      });
    }

    // Generate token
    const token = generateToken(user._id);

    // Remove password from response
    user.password = undefined;

    res.status(200).json({
      success: true,
      message: "Đăng nhập thành công",
      data: {
        token,
        user: {
          _id: user._id,
          fullname: user.fullname,
          email: user.email,
          phone: user.phone,
          avatar: user.avatar,
          membership: user.membership,
          smokingProfile: user.smokingProfile,
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

// @desc    Get current logged in user
// @route   GET /api/auth/profile
// @access  Private
const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    res.status(200).json({
      success: true,
      data: {
        _id: user._id,
        fullname: user.fullname,
        email: user.email,
        phone: user.phone,
        avatar: user.avatar,
        membership: user.membership,
        smokingProfile: user.smokingProfile,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Update user profile
// @route   PUT /api/auth/profile
// @access  Private
const updateProfile = async (req, res) => {
  try {
    const { fullname, phone, smokingProfile } = req.body;

    const updateQuery = { fullname, phone };
    if (smokingProfile) {
      if (smokingProfile.cigarettesPerDay !== undefined) updateQuery["smokingProfile.cigarettesPerDay"] = smokingProfile.cigarettesPerDay;
      if (smokingProfile.smokingYears !== undefined) updateQuery["smokingProfile.smokingYears"] = smokingProfile.smokingYears;
      if (smokingProfile.quitDate !== undefined) updateQuery["smokingProfile.quitDate"] = smokingProfile.quitDate;
      if (smokingProfile.morningCravingLevel !== undefined) updateQuery["smokingProfile.morningCravingLevel"] = smokingProfile.morningCravingLevel;
      if (smokingProfile.quitReason !== undefined) updateQuery["smokingProfile.quitReason"] = smokingProfile.quitReason;
    }

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { $set: updateQuery },
      { new: true, runValidators: true }
    );

    res.status(200).json({
      success: true,
      message: "Cập nhật thông tin thành công",
      data: {
        _id: user._id,
        fullname: user.fullname,
        email: user.email,
        phone: user.phone,
        avatar: user.avatar,
        smokingProfile: user.smokingProfile,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// @desc    Upload user avatar
// @route   POST /api/auth/avatar
// @access  Private
const uploadAvatar = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: "Vui lòng chọn ảnh để tải lên" });
    }

    const uploadResult = await new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        {
          folder: "quitcare/avatars",
          public_id: `user_${req.user.id}`,
          overwrite: true,
          transformation: [{ width: 400, height: 400, crop: "fill", gravity: "face" }],
        },
        (error, result) => {
          if (error) reject(error);
          else resolve(result);
        }
      );
      stream.end(req.file.buffer);
    });

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { avatar: uploadResult.secure_url },
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: "Cập nhật ảnh đại diện thành công",
      data: { avatar: user.avatar },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Change user password
// @route   PUT /api/auth/change-password
// @access  Private
const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ success: false, message: "Vui lòng nhập đầy đủ thông tin" });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({ success: false, message: "Mật khẩu mới phải có ít nhất 8 ký tự" });
    }

    const user = await User.findById(req.user.id).select("+password");

    const isMatch = await user.matchPassword(currentPassword);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: "Mật khẩu hiện tại không đúng" });
    }

    user.password = newPassword;
    await user.save();

    res.status(200).json({ success: true, message: "Đổi mật khẩu thành công" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export { register, login, getProfile, updateProfile, uploadAvatar, changePassword };
