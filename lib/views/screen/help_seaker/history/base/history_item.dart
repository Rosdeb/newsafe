import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../Models/ActivityHistory/activityHistory.dart';
import '../../../../../utils/app_color.dart';
import '../../../../base/AppText/appText.dart';

class HistoryItem extends StatelessWidget {
  final HistoryModel historyModel;
  const HistoryItem({required this.historyModel, super.key});

  @override
  Widget build(BuildContext context) {
    final isApproved = historyModel.status == "success"; // Check model status

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.iconBg.withOpacity(0.2),
        border: Border.all(width: 1.2, color: AppColors.colorYellow),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isApproved ? const Color(0xFF14532D) : const Color(0xFF7F1D1D),
            child: SvgPicture.asset(
              "assets/icon/Group (1).svg",
              height: 18,
              width: 18,
              color: isApproved ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(historyModel.title, fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.color2Box),
                    AppText(historyModel.date, fontSize: 12, fontWeight: FontWeight.w100, color: AppColors.color2Box),
                  ],
                ),
                const SizedBox(height: 5),
                // Details & time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(historyModel.details, fontSize: 14, fontWeight: FontWeight.w100, color: AppColors.color2Box),
                    AppText(historyModel.time, fontSize: 14, fontWeight: FontWeight.w100, color: AppColors.color2Box),
                  ],
                ),
                const SizedBox(height: 5),
                // Distance
                Row(
                  children: [
                    SvgPicture.asset("assets/icon/mi_location.svg"),
                    const SizedBox(width: 5),
                    AppText(historyModel.distance, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.color2Box),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}