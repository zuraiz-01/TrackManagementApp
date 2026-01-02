import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    required this.borderColor,
    required this.labelColor,
    required this.backgroundColor,
    required this.fontScale,
    required this.showFigureSection,
    required this.jodiStart,
    required this.jodiEnd,
    required this.figureStart,
    required this.figureEnd,
  });

  final Color borderColor;
  final Color labelColor;
  final Color backgroundColor;
  final double fontScale;

  final bool showFigureSection;
  final int jodiStart;
  final int jodiEnd;
  final int figureStart;
  final int figureEnd;

  static const AppSettings defaults = AppSettings(
    borderColor: Color(0xFFB0004B),
    labelColor: Color(0xFF49A7FF),
    backgroundColor: Color(0xFF0B0B0F),
    fontScale: 1.0,
    showFigureSection: true,
    jodiStart: 0,
    jodiEnd: 99,
    figureStart: 101,
    figureEnd: 120,
  );

  AppSettings copyWith({
    Color? borderColor,
    Color? labelColor,
    Color? backgroundColor,
    double? fontScale,
    bool? showFigureSection,
    int? jodiStart,
    int? jodiEnd,
    int? figureStart,
    int? figureEnd,
  }) {
    return AppSettings(
      borderColor: borderColor ?? this.borderColor,
      labelColor: labelColor ?? this.labelColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontScale: fontScale ?? this.fontScale,
      showFigureSection: showFigureSection ?? this.showFigureSection,
      jodiStart: jodiStart ?? this.jodiStart,
      jodiEnd: jodiEnd ?? this.jodiEnd,
      figureStart: figureStart ?? this.figureStart,
      figureEnd: figureEnd ?? this.figureEnd,
    );
  }
}
