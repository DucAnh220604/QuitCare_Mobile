import 'package:flutter/material.dart';
import '../constants/colors.dart';

class BangXepHangScreen extends StatelessWidget {
  const BangXepHangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        title: const Text('Bảng xếp hạng'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab(context, label: 'Tuần này', isActive: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTab(
                    context,
                    label: 'Tháng này',
                    isActive: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTab(
                    context,
                    label: 'Tất cả thời gian',
                    isActive: false,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(10, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRankCard(
                      context,
                      rank: index + 1,
                      name: 'Người dùng ${index + 1}',
                      score: (1000 - index * 50).toString(),
                      isCurrentUser: index == 2,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context, {
    required String label,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryBlue.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: AppColors.primaryBlue, width: 1.5)
            : null,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isActive ? AppColors.primaryBlue : AppColors.textSecondary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRankCard(
    BuildContext context, {
    required int rank,
    required String name,
    required String score,
    required bool isCurrentUser,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primaryBlue.withValues(alpha: 0.1)
            : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.primaryBlue, width: 1.5)
            : Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Điểm: $score',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Medal Icon for top 3
          if (rank <= 3)
            Icon(
              rank == 1
                  ? Icons.emoji_events
                  : rank == 2
                  ? Icons.military_tech
                  : Icons.leaderboard,
              color: _getRankColor(rank),
              size: 24,
            ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return AppColors.primaryBlue;
  }
}
