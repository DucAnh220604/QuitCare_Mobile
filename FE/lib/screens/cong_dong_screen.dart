import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CongDongScreen extends StatelessWidget {
  const CongDongScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        title: const Text('Cộng đồng'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Tìm kiếm bài viết...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  icon: const Icon(Icons.search, color: AppColors.primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Categories
            Text(
              'Danh mục',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCategory(context, icon: Icons.chat, label: 'Tất cả'),
                _buildCategory(
                  context,
                  icon: Icons.favorite,
                  label: 'Yêu thích',
                ),
                _buildCategory(
                  context,
                  icon: Icons.trending_up,
                  label: 'Xu hướng',
                ),
                _buildCategory(
                  context,
                  icon: Icons.schedule,
                  label: 'Mới nhất',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Posts
            Text(
              'Bài viết nổi bật',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: List.generate(5, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPostCard(
                    context,
                    author: 'Người dùng ${index + 1}',
                    title: 'Cách tôi vượt qua cơn thèm ngày thứ 30',
                    content:
                        'Hôm nay là ngày thứ 30 của hành trình bỏ thuốc của tôi. Nó không dễ dàng...',
                    likes: (100 + index * 20),
                    comments: (10 + index * 5),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: AppColors.primaryBlue, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(
    BuildContext context, {
    required String author,
    required String title,
    required String content,
    required int likes,
    required int comments,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '2 giờ trước',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 12),

          // Title & Content
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAction(
                context,
                icon: Icons.favorite_border,
                label: '$likes',
              ),
              _buildAction(
                context,
                icon: Icons.comment_outlined,
                label: '$comments',
              ),
              _buildAction(
                context,
                icon: Icons.share_outlined,
                label: 'Chia sẻ',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAction(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 18),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
