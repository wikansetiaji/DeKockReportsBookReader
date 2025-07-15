import 'package:flutter/widgets.dart';

class SizeConfig {
  static late double screenWidth;
  static late double screenHeight;
  static late double scaleFactor;

  static void init(BuildContext context) {
    final MediaQueryData mqData = MediaQuery.of(context);
    screenWidth = mqData.size.width;
    screenHeight = mqData.size.height;

    // Base dimensions from your FHD design
    const double baseWidth = 1133;
    const double baseHeight = 744;

    // You can use either width, height, or average scaling
    scaleFactor = (screenWidth / baseWidth + screenHeight / baseHeight) / 2;
  }

  static double scaledSize(double size) {
    return size * scaleFactor;
  }
}

extension SizeConfigExtension on num {
  double get sc => SizeConfig.scaledSize(toDouble());
}