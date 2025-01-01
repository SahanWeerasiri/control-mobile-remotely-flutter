import 'package:flutter/material.dart';

class AppSizes {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;

  void initSizes(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
  }

  double getBlockSizeHorizontal(double percentage) {
    return blockSizeHorizontal * percentage;
  }

  double getBlockSizeVertical(double percentage) {
    return blockSizeVertical * percentage;
  }

  double getScreenWidth() {
    return screenWidth;
  }

  double getScreenHeight() {
    return screenHeight;
  }
}
