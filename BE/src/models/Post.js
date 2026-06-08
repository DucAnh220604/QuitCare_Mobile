import mongoose from "mongoose";

const postSchema = new mongoose.Schema(
  {
    authorName: {
      type: String,
      default: "Ẩn danh",
      trim: true,
    },
    content: {
      type: String,
      required: [true, "Nội dung bài viết không được để trống"],
      trim: true,
      maxlength: [1000, "Nội dung không quá 1000 ký tự"],
    },
    likesCount: { type: Number, default: 0 },
    commentsCount: { type: Number, default: 0 },
    likedBy: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
  },
  { timestamps: true }
);

const Post = mongoose.model("Post", postSchema);
export default Post;
