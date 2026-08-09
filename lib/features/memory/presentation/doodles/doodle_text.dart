import 'package:flutter/material.dart';

enum DoodleTextAlign {
  left,
  center,
  right,
}

enum DoodleTextBubble {
  none,
  pill,
  speech,
  cloud,
  highlight,
  badge,
  softCard,
}

class DoodleText {
  const DoodleText({
    required this.id,
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
    required this.scale,
    required this.rotation,
    required this.zIndex,
    required this.alignment,
    this.fontFamily,
    this.bold = false,
    this.shadowEnabled = false,
    this.outlineEnabled = false,
    this.outlineColor = Colors.black,
    this.curveAmount = 0,
    this.bubble = DoodleTextBubble.none,
    this.bubbleColor = Colors.white,
    this.bubbleOpacity = 0.9,
  });

  final String id;

  final String text;

  final Offset position;

  final Color color;

  final double fontSize;

  final double scale;

  final double rotation;

  final int zIndex;

  final DoodleTextAlign alignment;

  final String? fontFamily;

  final bool bold;

  final bool shadowEnabled;

  final bool outlineEnabled;

  final Color outlineColor;

  /// -1.0 = strong downward curve
  ///  0.0 = straight
  ///  1.0 = strong upward curve
  final double curveAmount;

  final DoodleTextBubble bubble;

  final Color bubbleColor;

  final double bubbleOpacity;

  DoodleText copyWith({
    String? id,
    String? text,
    Offset? position,
    Color? color,
    double? fontSize,
    double? scale,
    double? rotation,
    int? zIndex,
    DoodleTextAlign? alignment,
    String? fontFamily,
    bool? bold,
    bool? shadowEnabled,
    bool? outlineEnabled,
    Color? outlineColor,
    double? curveAmount,
    DoodleTextBubble? bubble,
    Color? bubbleColor,
    double? bubbleOpacity,
  }) {
    return DoodleText(
      id: id ?? this.id,
      text: text ?? this.text,
      position: position ?? this.position,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      alignment: alignment ?? this.alignment,
      fontFamily: fontFamily ?? this.fontFamily,
      bold: bold ?? this.bold,
      shadowEnabled: shadowEnabled ?? this.shadowEnabled,
      outlineEnabled: outlineEnabled ?? this.outlineEnabled,
      outlineColor: outlineColor ?? this.outlineColor,
      curveAmount: curveAmount ?? this.curveAmount,
      bubble: bubble ?? this.bubble,
      bubbleColor: bubbleColor ?? this.bubbleColor,
      bubbleOpacity: bubbleOpacity ?? this.bubbleOpacity,
    );
  }
}