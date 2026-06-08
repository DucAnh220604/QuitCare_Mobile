import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/community_service.dart';

class CongDongScreen extends StatefulWidget {
  const CongDongScreen({super.key});

  @override
  State<CongDongScreen> createState() => _CongDongScreenState();
}

class _CongDongScreenState extends State<CongDongScreen> {
  final _service = CommunityService();
  final _scrollCtrl = ScrollController();

  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  static const _limit = 10;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        !_isLoadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadPosts() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await _service.getPosts(page: 1, limit: _limit);
    if (!mounted) return;
    if (result['success'] == true) {
      final raw = result['data'] as List<dynamic>? ?? [];
      setState(() {
        _posts = raw.cast<Map<String, dynamic>>();
        _page = 1;
        _hasMore = (result['totalPages'] as int? ?? 1) > 1;
        _isLoading = false;
      });
    } else {
      setState(() { _isLoading = false; _error = result['message'] as String?; });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    final nextPage = _page + 1;
    final result = await _service.getPosts(page: nextPage, limit: _limit);
    if (!mounted) return;
    if (result['success'] == true) {
      final raw = result['data'] as List<dynamic>? ?? [];
      final totalPages = result['totalPages'] as int? ?? 1;
      setState(() {
        _posts.addAll(raw.cast<Map<String, dynamic>>());
        _page = nextPage;
        _hasMore = nextPage < totalPages;
        _isLoadingMore = false;
      });
    } else {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refresh() async {
    setState(() { _page = 1; _hasMore = true; });
    await _loadPosts();
  }

  // ── Optimistic like ──────────────────────────────────────────────────────
  Future<void> _toggleLike(int idx) async {
    final post = Map<String, dynamic>.from(_posts[idx]);
    final wasLiked = post['isLiked'] as bool? ?? false;
    final prevCount = post['likesCount'] as int? ?? 0;

    setState(() {
      _posts[idx] = {
        ...post,
        'isLiked': !wasLiked,
        'likesCount': wasLiked ? (prevCount - 1).clamp(0, 9999) : prevCount + 1,
      };
    });

    final result = await _service.toggleLike(post['_id'] as String);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _posts[idx] = {
          ..._posts[idx],
          'isLiked': result['isLiked'] as bool? ?? !wasLiked,
          'likesCount': result['likesCount'] as int? ?? _posts[idx]['likesCount'],
        };
      });
    } else {
      setState(() { _posts[idx] = post; });
    }
  }

  // ── Comments ─────────────────────────────────────────────────────────────
  void _showComments(Map<String, dynamic> post, int idx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CommentsSheet(
        post: post,
        service: _service,
        onCommentAdded: () {
          setState(() {
            _posts[idx] = {
              ..._posts[idx],
              'commentsCount': (_posts[idx]['commentsCount'] as int? ?? 0) + 1,
            };
          });
        },
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildSkeleton()
                  : _error != null
                      ? _buildError()
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          color: AppColors.primaryBlue,
                          child: _posts.isEmpty
                              ? _buildEmpty()
                              : ListView.builder(
                                  controller: _scrollCtrl,
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                                  itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
                                  itemBuilder: (_, i) {
                                    if (i == _posts.length) return _buildLoadingMore();
                                    return _PostCard(
                                      post: _posts[i],
                                      onLike: () => _toggleLike(i),
                                      onComment: () => _showComments(_posts[i], i),
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final canPop = Navigator.canPop(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFDFD),
      ),
      child: Row(
        children: [
          if (canPop)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.chevron_left, color: Color(0xFF1E293B), size: 20),
              ),
            )
          else
            const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cộng đồng',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLoading
                      ? 'Đang tải...'
                      : 'Khám phá ${_posts.length}+ câu chuyện',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(CupertinoIcons.person_2_fill, color: Color(0xFF6B4EFF), size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: 4,
      itemBuilder: (context, i) => const _SkeletonCard(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.wifi_slash, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(_error ?? 'Lỗi tải dữ liệu',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadPosts, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        const Icon(CupertinoIcons.chat_bubble_2, size: 64, color: AppColors.textTertiary),
        const SizedBox(height: 16),
        const Text('Chưa có bài viết nào',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text('Những câu chuyện truyền cảm hứng sẽ sớm xuất hiện ở đây.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ],
    );
  }

  Widget _buildLoadingMore() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  POST CARD
// ─────────────────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onComment,
  });

  final Map<String, dynamic> post;
  final VoidCallback onLike;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final authorName = (post['authorName'] as String?) ?? 'Ẩn danh';
    final content = (post['content'] as String?) ?? '';
    final isLiked = post['isLiked'] as bool? ?? false;
    final likesCount = post['likesCount'] as int? ?? 0;
    final commentsCount = post['commentsCount'] as int? ?? 0;
    final createdAt = (post['createdAt'] as String?) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                _Avatar(name: authorName),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authorName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF1E293B))),
                      const SizedBox(height: 2),
                      Text(_timeAgo(createdAt),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Text(content,
                style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF334155),
                    height: 1.6)),
          ),

          // Divider
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _ActionBtn(
                  icon: isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                  iconColor: isLiked ? const Color(0xFFF43F5E) : const Color(0xFF94A3B8),
                  label: '$likesCount',
                  bgColor: isLiked ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
                  onTap: onLike,
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: CupertinoIcons.chat_bubble_fill,
                  iconColor: const Color(0xFF6B4EFF),
                  label: '$commentsCount',
                  bgColor: const Color(0xFFF3F0FF),
                  onTap: onComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _timeAgo(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} tháng trước';
    return '${(diff.inDays / 365).floor()} năm trước';
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.bgColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: iconColor)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AVATAR
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  static const _colors = [
    Color(0xFF6B4EFF),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFFF43F5E),
    Color(0xFF0EA5E9),
  ];

  @override
  Widget build(BuildContext context) {
    final idx = name.isEmpty ? 0 : name.codeUnits.fold(0, (s, c) => s + c) % _colors.length;
    final color = _colors[idx];
    final initials = _initials(name);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initials,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  COMMENTS BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({
    required this.post,
    required this.service,
    required this.onCommentAdded,
  });
  final Map<String, dynamic> post;
  final CommunityService service;
  final VoidCallback onCommentAdded;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final postId = widget.post['_id'] as String;
    final result = await widget.service.getComments(postId);
    if (!mounted) return;
    if (result['success'] == true) {
      final raw = result['data'] as List<dynamic>? ?? [];
      setState(() {
        _comments = raw.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    _ctrl.clear();

    final postId = widget.post['_id'] as String;
    final result = await widget.service.addComment(postId, text);
    if (!mounted) return;
    if (result['success'] == true) {
      final newComment = result['data'] as Map<String, dynamic>;
      setState(() {
        _comments.add(newComment);
        _isSending = false;
      });
      widget.onCommentAdded();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    } else {
      setState(() => _isSending = false);
    }
  }

  Future<void> _deleteComment(String commentId, int idx) async {
    final result = await widget.service.deleteComment(commentId);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() => _comments.removeAt(idx));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final commentsCount = widget.post['commentsCount'] as int? ?? _comments.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFDDE1E7),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(CupertinoIcons.chat_bubble_2, size: 18, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Text('Bình luận ($commentsCount)',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(CupertinoIcons.xmark_circle_fill,
                      size: 24, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _comments.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.chat_bubble, size: 40, color: AppColors.textTertiary),
                            SizedBox(height: 10),
                            Text('Chưa có bình luận nào',
                                style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _comments.length,
                        itemBuilder: (_, i) => _CommentTile(
                          comment: _comments[i],
                          onDelete: () => _deleteComment(
                              _comments[i]['_id'] as String, i),
                        ),
                      ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        hintText: 'Viết bình luận...',
                        hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                      ),
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _ctrl.text.trim().isEmpty ? null : _addComment,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _ctrl.text.trim().isEmpty
                          ? const Color(0xFFCBD5E1)
                          : AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(CupertinoIcons.paperplane_fill,
                            color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.onDelete});
  final Map<String, dynamic> comment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final authorName = (comment['authorName'] as String?) ?? 'Người dùng';
    final content = (comment['content'] as String?) ?? '';
    final isOwner = comment['isOwner'] as bool? ?? false;
    final createdAt = (comment['createdAt'] as String?) ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(name: authorName),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authorName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(content,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(_timeAgo(createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                    if (isOwner) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Text('Xóa',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _timeAgo(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${(diff.inDays / 30).floor()} tháng trước';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SKELETON LOADING CARD
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmer(38, 38, circle: true),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmer(120, 12),
                  const SizedBox(height: 6),
                  _shimmer(80, 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _shimmer(double.infinity, 12),
          const SizedBox(height: 6),
          _shimmer(double.infinity, 12),
          const SizedBox(height: 6),
          _shimmer(160, 12),
        ],
      ),
    );
  }

  static Widget _shimmer(double w, double h, {bool circle = false}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF0),
        borderRadius: circle ? null : BorderRadius.circular(6),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}
