import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/case.dart';

class TaskModel extends ChangeNotifier {

  List<Case> cases = [];

  bool isCanceled = false;
  bool isOnTask = false;
  bool isOpenCaseRefresh = false;
  // List<Position> routePositions = [];
  double currentTaskPrice = 0;
  double totalDistance = 0;
  // int secondTotal = 0;

  DateTime? lastRecordTime;
  double currentVelocity = -1;
  double? _trackLatitude;
  double? _trackLongitude;

  DateTime? startTime;

  String? feeTitle;
  int startFee = 50;
  double fifteenSecondFee = 0.5;
  double twoHundredMeterFee = 4;

  void addCase(Case newCase){
    cases.add(newCase);
    notifyListeners();
  }

  /// 新任務開始時清掉上一點，避免把上一趟的位移算進來。
  void beginDistanceTracking({double? latitude, double? longitude}) {
    _trackLatitude = latitude;
    _trackLongitude = longitude;
  }

  /// 用實際座標累加里程。外掛的 odometer 在 iOS 27 會停在 0，路線點卻仍有寫入。
  /// 精準度無效或超過 200 公尺的點略過，10 公尺以內視為靜止抖動。
  double appendTrackedPoint(double latitude, double longitude, double accuracy) {
    if (accuracy < 0 || accuracy > 200) {
      return 0;
    }
    final lastLat = _trackLatitude;
    final lastLng = _trackLongitude;
    if (lastLat == null || lastLng == null) {
      _trackLatitude = latitude;
      _trackLongitude = longitude;
      return 0;
    }
    final meters = Geolocator.distanceBetween(lastLat, lastLng, latitude, longitude);
    if (meters < 10) {
      return 0;
    }
    _trackLatitude = latitude;
    _trackLongitude = longitude;
    totalDistance += meters / 1000.0;
    notifyListeners();
    return meters;
  }

  int getSecondsTotal(){
    int secondTotal = 0;
    if(startTime!=null){
      DateTime currentTime = DateTime.now();
      secondTotal = currentTime.difference(startTime!).inSeconds;
    }
    return secondTotal;
  }

  Future<void> setCurrentTaskPrice(int dispatchCarTeamId) async {

    int secondTotal = 0;

    if(startTime!=null){
      DateTime currentTime = DateTime.now();
      secondTotal = currentTime.difference(startTime!).inSeconds;
    }

    if(totalDistance >= 0.01){
      int totalDistanceInMeter = (totalDistance * 1000).floor();
      int times = totalDistanceInMeter ~/ 25;
      double twentyFiveMeterFee = twoHundredMeterFee / 8;

      currentTaskPrice = startFee.toDouble() + times * twentyFiveMeterFee;

    }else{
      currentTaskPrice = startFee.toDouble();
    }

    int times = secondTotal~/15;
    currentTaskPrice = currentTaskPrice +  times * fifteenSecondFee;

    if(cases[0].isUseProcessedTaskMoney == true && currentTaskPrice < 100){
      currentTaskPrice = 100;
    }else if(cases[0].isUseProcessedTaskMoney == false && currentTaskPrice < 80){
      currentTaskPrice = 80;
    }else{
      currentTaskPrice = adjustTaskPrice(currentTaskPrice, dispatchCarTeamId);
    }

    notifyListeners();
  }

  double adjustTaskPrice(double currentTaskPrice, int dispatchCarTeamId) {
    print('price before adjust $currentTaskPrice');

    int roundedPrice = currentTaskPrice.round();
    return ((roundedPrice / 10).floor() * 10).toDouble();
    
  }

  Future<void> resetTask() async {
    currentTaskPrice = 0;
    totalDistance = 0;
    // routePositions.clear();
    isOnTask = false;
    lastRecordTime = null;
    currentVelocity = -1;
    _trackLatitude = null;
    _trackLongitude = null;
    startTime = null;

    //移除最上面那個 case
    cases.removeAt(0);
    if (cases.isEmpty) {
      await clearOnTaskPref();
    }
    notifyListeners();
  }

  static Future<void> saveOnTaskPref(DateTime confirmTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_on_task', true);
    await prefs.setString('case_confirm_time', confirmTime.toIso8601String());
  }

  static Future<void> clearOnTaskPref() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_on_task', false);
    await prefs.remove('case_confirm_time');
  }

  /// 確認後 1 小時內，回到首頁時改由司機手動拉回進行中的單。
  static Future<bool> shouldRecoverOnTask() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('is_on_task') != true) {
      return false;
    }
    final raw = prefs.getString('case_confirm_time');
    final confirmTime = raw == null ? null : DateTime.tryParse(raw);
    if (confirmTime == null ||
        DateTime.now().difference(confirmTime) >= const Duration(hours: 1)) {
      await clearOnTaskPref();
      return false;
    }
    return true;
  }

}