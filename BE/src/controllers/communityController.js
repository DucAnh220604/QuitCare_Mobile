import Post from "../models/Post.js";
import Comment from "../models/Comment.js";

// @desc  Get paginated posts
// @route GET /api/community/posts?page=1&limit=10
// @access Private
export const getPosts = async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(20, parseInt(req.query.limit) || 10);
    const skip = (page - 1) * limit;

    const [total, posts] = await Promise.all([
      Post.countDocuments(),
      Post.find().sort({ createdAt: -1 }).skip(skip).limit(limit),
    ]);

    const currentUserId = req.user.id;
    const data = posts.map((post) => ({
      _id: post._id,
      content: post.content,
      authorName: post.authorName || "Ẩn danh",
      likesCount: post.likesCount,
      commentsCount: post.commentsCount,
      isLiked: post.likedBy.some((id) => id.toString() === currentUserId),
      createdAt: post.createdAt,
    }));

    res.status(200).json({
      success: true,
      data,
      total,
      page,
      totalPages: Math.ceil(total / limit),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc  Toggle like on a post
// @route POST /api/community/posts/:id/like
// @access Private
export const toggleLike = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ success: false, message: "Không tìm thấy bài viết" });

    const userId = req.user.id;
    const alreadyLiked = post.likedBy.some((id) => id.toString() === userId);

    if (alreadyLiked) {
      post.likedBy = post.likedBy.filter((id) => id.toString() !== userId);
      post.likesCount = Math.max(0, post.likesCount - 1);
    } else {
      post.likedBy.push(userId);
      post.likesCount += 1;
    }

    await post.save();
    res.status(200).json({ success: true, isLiked: !alreadyLiked, likesCount: post.likesCount });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc  Get comments for a post
// @route GET /api/community/posts/:id/comments
// @access Private
export const getComments = async (req, res) => {
  try {
    const comments = await Comment.find({ postId: req.params.id })
      .sort({ createdAt: 1 })
      .populate("userId", "fullname");

    const currentUserId = req.user.id;
    res.status(200).json({
      success: true,
      data: comments.map((c) => ({
        _id: c._id,
        content: c.content,
        authorName: c.userId?.fullname || "Ẩn danh",
        isOwner: c.userId?._id.toString() === currentUserId,
        createdAt: c.createdAt,
      })),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc  Add comment to a post
// @route POST /api/community/posts/:id/comments
// @access Private
export const addComment = async (req, res) => {
  try {
    const { content } = req.body;
    if (!content?.trim()) {
      return res.status(400).json({ success: false, message: "Nội dung không được để trống" });
    }

    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ success: false, message: "Không tìm thấy bài viết" });

    const comment = await Comment.create({
      postId: req.params.id,
      userId: req.user.id,
      content: content.trim(),
    });

    post.commentsCount += 1;
    await Promise.all([post.save(), comment.populate("userId", "fullname")]);

    res.status(201).json({
      success: true,
      data: {
        _id: comment._id,
        content: comment.content,
        authorName: comment.userId?.fullname || "Ẩn danh",
        isOwner: true,
        createdAt: comment.createdAt,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc  Delete own comment
// @route DELETE /api/community/comments/:id
// @access Private
export const deleteComment = async (req, res) => {
  try {
    const comment = await Comment.findById(req.params.id);
    if (!comment) return res.status(404).json({ success: false, message: "Không tìm thấy bình luận" });
    if (comment.userId.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: "Không có quyền xóa bình luận này" });
    }

    await Promise.all([
      Comment.findByIdAndDelete(req.params.id),
      Post.findByIdAndUpdate(comment.postId, { $inc: { commentsCount: -1 } }),
    ]);

    res.status(200).json({ success: true, message: "Xóa bình luận thành công" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const SEED_POSTS = [
  { authorName: "Minh Tuấn", content: "Hôm nay là ngày thứ 30 tôi không hút thuốc! Cảm giác thật sự rất tuyệt vời, hơi thở dễ chịu hơn rất nhiều. Ai đang ở những ngày đầu đừng bỏ cuộc nhé, nó xứng đáng lắm!", likesCount: 42 },
  { authorName: "Lan Anh", content: "Chia sẻ mẹo nhỏ giúp mình vượt qua cơn thèm thuốc: uống 1 ly nước lạnh, hít thở sâu 10 lần, rồi đi bộ 5 phút. Nghe có vẻ đơn giản nhưng thật sự hiệu quả với mình lắm!", likesCount: 35 },
  { authorName: "Đức Hùng", content: "Tuần đầu tiên là khó khăn nhất. Mình đã suýt bỏ cuộc vào ngày thứ 3 nhưng nghĩ đến con gái mình lại gắng lên. Giờ đã được 2 tháng rồi, mọi người cố lên!", likesCount: 67 },
  { authorName: "Thu Hương", content: "Tiết kiệm được 1.500.000đ sau 1 tháng không hút thuốc. Mình dùng số tiền đó mua quà cho gia đình. Cảm giác hạnh phúc hơn hẳn so với việc đốt tiền vào thuốc lá.", likesCount: 89 },
  { authorName: "Văn Khoa", content: "Mình hút thuốc 15 năm, bây giờ được 45 ngày sạch rồi. Bác sĩ nói chức năng phổi đã cải thiện đáng kể. Đừng nghĩ là đã muộn, bắt đầu lúc nào cũng được!", likesCount: 54 },
  { authorName: "Phương Linh", content: "Cơn thèm thuốc chỉ kéo dài khoảng 3–5 phút thôi. Mình đặt đồng hồ đếm ngược mỗi lần thèm và nhận ra nó qua đi rất nhanh. Mẹo này giúp mình nhiều lắm.", likesCount: 28 },
  { authorName: "Thanh Bình", content: "Ngày hôm nay mình đã leo được 5 tầng cầu thang mà không bị hụt hơi. Trước đây leo 2 tầng đã mệt rồi. 3 tuần không hút thuốc, phổi đã khác hẳn!", likesCount: 73 },
  { authorName: "Hoàng Nam", content: "Vừa trải qua một buổi tiệc có rất nhiều người hút thuốc xung quanh mà mình không bị lung lay. Ai nói môi trường không ảnh hưởng được, hãy bước qua khi ý chí đủ mạnh. Tự hào về bản thân lắm!", likesCount: 61 },
  { authorName: "Ngọc Mai", content: "Mình dùng app này để theo dõi tiến trình và thấy rất có động lực khi nhìn streak tăng dần mỗi ngày. Cảm ơn cộng đồng đã luôn động viên. Cùng nhau cố gắng nha mọi người!", likesCount: 45 },
  { authorName: "Quang Vinh", content: "Thất bại lần này là lần thứ 3 mình cố gắng bỏ thuốc. Nhưng lần này mình có app hỗ trợ và cộng đồng đồng hành nên cảm thấy tự tin hơn nhiều. Quyết tâm lần này sẽ thành công!", likesCount: 38 },
  { authorName: "Bảo Long", content: "Con mình (8 tuổi) nói: 'Ba không còn hôi thuốc nữa, con thích ba hôn má hơn rồi'. Câu nói đó làm mình rơi nước mắt và quyết tâm không bao giờ cầm điếu thuốc nữa.", likesCount: 124 },
  { authorName: "Hải Yến", content: "Tips cho anh em mới bắt đầu: thay điếu thuốc bằng kẹo cao su không đường hoặc hạt hướng dương. Tay và miệng cần làm gì đó thì cho chúng làm thứ khác. Hiệu quả với mình lắm!", likesCount: 52 },
  { authorName: "Trọng Nghĩa", content: "100 ngày không hút thuốc hôm nay! Từ người hút 1 bao/ngày giờ đây đã hoàn toàn sạch. Sức khỏe tốt hơn, tiết kiệm hơn và quan trọng nhất là tự hào về bản thân.", likesCount: 156 },
  { authorName: "Kim Chi", content: "Mình nhận ra mình hút thuốc nhiều nhất khi stress hoặc nhàm chán. Bây giờ mình thay thế bằng thiền 5 phút hoặc nghe nhạc. Đã 3 tuần và cảm thấy cân bằng hơn hẳn.", likesCount: 41 },
  { authorName: "Anh Khoa", content: "Mới check-in ngày đầu tiên. Hút thuốc 10 năm, hôm nay chính thức bắt đầu hành trình. Sợ lắm nhưng quyết tâm. Mọi người cổ vũ mình với!", likesCount: 97 },
  { authorName: "Minh Phúc", content: "Hút thuốc từ năm 18 tuổi, nay 35 tuổi mới dứt khoát bỏ. Sau 60 ngày, con số tiết kiệm nhìn vào mà sướng lắm. Mỗi tuần mình tự thưởng một món ăn ngon thay vì mua thuốc.", likesCount: 83 },
  { authorName: "Diễm Hương", content: "Chồng mình bỏ thuốc cùng lúc với mình nên hai vợ chồng động viên nhau mỗi ngày. Có người đồng hành thật sự rất khác, không còn cô đơn trong hành trình này nữa!", likesCount: 119 },
  { authorName: "Tuấn Kiệt", content: "Bí quyết của mình: xóa hết contact của người bán thuốc, không giữ tiền lẻ trong ví, và mỗi tối trước khi ngủ tự nhắc bản thân lý do mình bỏ thuốc. Ngày 22 rồi!", likesCount: 66 },
  { authorName: "Bích Ngọc", content: "Lần đầu chạy bộ 3km mà không dừng lại sau 5 tuần bỏ thuốc. Trước đây chạy 500m là thở không được. Sức khỏe cải thiện rõ rệt, mọi người hãy tin vào bản thân nhé!", likesCount: 77 },
  { authorName: "Hữu Đức", content: "Ai bảo bỏ thuốc khó lắm? Khó thật đấy nhưng không phải không thể. Mình đã thất bại 4 lần trước đây. Lần thứ 5 này mình học được rằng phải chuẩn bị tâm lý kỹ hơn. Ngày 90 hôm nay!", likesCount: 203 },
];

// Standalone seed function — called at server startup
export const runSeed = async () => {
  try {
    const existing = await Post.countDocuments();
    if (existing > 0) {
      console.log(`[Community] ${existing} posts already exist, skipping seed.`);
      return;
    }
    await Post.insertMany(SEED_POSTS);
    console.log(`[Community] Seeded ${SEED_POSTS.length} sample posts.`);
  } catch (err) {
    console.error("[Community] Seed failed:", err.message);
  }
};

// @desc  Seed via HTTP (idempotent)
// @route POST /api/community/seed
// @access Public
export const seedPosts = async (req, res) => {
  try {
    const existing = await Post.countDocuments();
    if (existing > 0) {
      return res.status(200).json({
        success: true,
        message: `Đã có ${existing} bài viết, bỏ qua seed.`,
      });
    }
    await Post.insertMany(SEED_POSTS);
    res.status(201).json({
      success: true,
      message: `Đã tạo ${SEED_POSTS.length} bài viết mẫu thành công.`,
      count: SEED_POSTS.length,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
