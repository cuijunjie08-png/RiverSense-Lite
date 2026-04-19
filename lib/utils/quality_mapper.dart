import 'package:flutter/material.dart';

enum WaterQualityStatus { good, moderate, poor, unknown }

class WaterQualityPresentation {
  final WaterQualityStatus status;
  final String label;
  final Color color;
  final IconData icon;
  final String explanation;

  const WaterQualityPresentation({
    required this.status,
    required this.label,
    required this.color,
    required this.icon,
    required this.explanation,
  });
}

class QualityMapper {
  // 先做 pH 的翻译逻辑
  // 后面如果你接入 dissolved oxygen / turbidity / conductivity，
  // 再继续扩展不同参数的规则
  static WaterQualityPresentation mapPh(double? value) {
    if (value == null) {
      return const WaterQualityPresentation(
        status: WaterQualityStatus.unknown,
        label: 'Unknown',
        color: Colors.grey,
        icon: Icons.help_outline,
        explanation: 'No valid reading is currently available for this site.',
      );
    }

    if (value >= 6.5 && value <= 8.5) {
      return WaterQualityPresentation(
        status: WaterQualityStatus.good,
        label: 'Good',
        color: Colors.green.shade700,
        icon: Icons.check_circle_outline,
        explanation:
            'The latest pH reading is within a generally acceptable range for river water.',
      );
    }

    if ((value >= 6.0 && value < 6.5) || (value > 8.5 && value <= 9.0)) {
      return WaterQualityPresentation(
        status: WaterQualityStatus.moderate,
        label: 'Moderate',
        color: Colors.orange.shade700,
        icon: Icons.warning_amber_outlined,
        explanation:
            'The latest pH reading is slightly outside the preferred range and may deserve attention.',
      );
    }

    return WaterQualityPresentation(
      status: WaterQualityStatus.poor,
      label: 'Poor',
      color: Colors.red.shade700,
      icon: Icons.error_outline,
      explanation:
          'The latest pH reading is notably outside the preferred range and may indicate poorer water conditions.',
    );
  }
}
