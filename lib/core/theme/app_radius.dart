import 'package:flutter/widgets.dart';

/// Shared corner radii. The app moved from hard pixel edges to soft rounded
/// surfaces; these keep cards, chips, buttons and inputs consistent.
class AppRadius {
  AppRadius._();

  static const double card = 14;
  static const double button = 12;
  static const double input = 12;
  static const double chip = 10;
  static const double small = 8;

  static BorderRadius get rCard => BorderRadius.circular(card);
  static BorderRadius get rButton => BorderRadius.circular(button);
  static BorderRadius get rChip => BorderRadius.circular(chip);
  static BorderRadius get rSmall => BorderRadius.circular(small);
}
