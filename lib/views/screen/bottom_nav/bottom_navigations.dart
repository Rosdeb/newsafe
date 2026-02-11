import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:saferader/utils/app_color.dart';
class IosStyleBottomNavigations extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const IosStyleBottomNavigations({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  Color _getColor(int index) => index == currentIndex ? AppColors.colorIcons : AppColors.color2Box;

  static const List<String> Icons = [
    'assets/icon/iconamoon_home.svg',
    'assets/icon/tdesign_location.svg',
    'assets/icon/notifications_none.svg',
    'assets/icon/material-symbols_history.svg',
    'assets/icon/solar_settings-outline.svg',

  ];

  static const List<String> labels =[
    'Home',
    'Location',
    'Notification',
    'History',
    'Setting',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: Colors.grey.shade300,
              width: 0.5
          ),
        ),
        child:SafeArea(
            child: Container(
              color: Colors.transparent,
              padding:const EdgeInsets.only(top: 10),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(labels.length, (index)=>_buildNavItem(index))
              ),
            ),
        ),
        );
  }

  Widget _buildNavItem(int index) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact(); // iOS-style feedback
        onTap(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        decoration: BoxDecoration(
          color: isSelected? const Color(0xFFFDE047).withOpacity(0.20) : Colors.transparent,
          borderRadius: BorderRadius.circular(8)
        ),
        duration: const Duration(milliseconds: 200),
        padding:const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              curve: Curves.fastOutSlowIn,
              duration: const Duration(milliseconds: 200),
              child: SvgPicture.asset(
                isSelected ? Icons[index] : Icons[index] ,
                height: 26.0,
                width: 26.0,
                color: _getColor(index),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              curve: Curves.fastOutSlowIn,
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 12 : 11,
                letterSpacing: 0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: _getColor(index),
              ),
              child: Text(labels[index]),
            ),
          ],
        ),
      ),
    );
  }

}
