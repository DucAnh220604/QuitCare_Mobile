import express from "express";
import auth from "../middleware/auth.js";
import {
  getPosts,
  toggleLike,
  getComments,
  addComment,
  deleteComment,
  seedPosts,
} from "../controllers/communityController.js";

const router = express.Router();

// Public seed (run once)
router.post("/seed", seedPosts);

// Posts (read + like)
router.get("/posts", auth, getPosts);
router.post("/posts/:id/like", auth, toggleLike);

// Comments
router.get("/posts/:id/comments", auth, getComments);
router.post("/posts/:id/comments", auth, addComment);
router.delete("/comments/:id", auth, deleteComment);

export default router;
