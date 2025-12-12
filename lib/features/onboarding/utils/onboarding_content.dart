import 'package:flutter/material.dart';

class TutorialContent {
  final IconData icon;
  final String title;
  final String description;
  final String tip;

  const TutorialContent({
    required this.icon,
    required this.title,
    required this.description,
    required this.tip,
  });
}

enum Feature { ocr, groups, payments }

const Map<Feature, TutorialContent> tutorials = {
  Feature.ocr: TutorialContent(
    icon: Icons.camera_alt,
    title: 'Scan Receipts Instantly',
    description: 'Just snap a photo and let AI do the work',
    tip: 'Works with any receipt format',
  ),
  Feature.groups: TutorialContent(
    icon: Icons.groups,
    title: 'Split with Groups',
    description: 'Create groups for friends, family, or colleagues',
    tip: 'Save groups for recurring expenses',
  ),
  Feature.payments: TutorialContent(
    icon: Icons.payments,
    title: 'Track Payments Easily',
    description: 'See who paid, who owes, and settle up',
    tip: 'Get payment history and reminders',
  ),
};
