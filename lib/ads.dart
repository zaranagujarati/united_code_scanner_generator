import 'dart:io';

class AdMobService
{
  static String? get rewardedAdUnitId
   {
    if(Platform.isAndroid)
      {
        return 'ca-app-pub-8347273600047970/9813076104';
      }
  }

  static String? get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-8347273600047970/6819307175';
    }
    return null;
  }
}