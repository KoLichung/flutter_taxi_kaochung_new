import 'package:flutter/cupertino.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
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

  DateTime? startTime;

  String? feeTitle;
  int startFee = 50;
  double fifteenSecondFee = 0.5;
  double twoHundredMeterFee = 4;

  void addCase(Case newCase){
    cases.add(newCase);
    notifyListeners();
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

      // EDM 超過 15 km, 每多完成 1km, 多 5 元
      if (dispatchCarTeamId == 6){
        if(totalDistanceInMeter > 1000){
          // Calculate the additional fee for every 1000 meters beyond 15000 meters
          int additionalFee = ((totalDistanceInMeter - 1000) / 1000).floor() * 5;
          currentTaskPrice = startFee.toDouble() + times * twentyFiveMeterFee + additionalFee;
        }else{
          currentTaskPrice = startFee.toDouble() + times * twentyFiveMeterFee;
        }
      }else{
        currentTaskPrice = startFee.toDouble() + times * twentyFiveMeterFee;
      }
    }else{
      currentTaskPrice = startFee.toDouble();
    }

    int times = secondTotal~/15;
    currentTaskPrice = currentTaskPrice +  times * fifteenSecondFee;

    currentTaskPrice = adjustTaskPrice(currentTaskPrice, dispatchCarTeamId);
    // print('current velocity $currentVelocity');
    // print('total distance $totalDistance');
    // print('startTime $startTime');
    // print('total second $secondTotal');
    notifyListeners();
  }

  double adjustTaskPrice(double currentTaskPrice, int dispatchCarTeamId) {
    print('price before adjust $currentTaskPrice');
    if (dispatchCarTeamId == 6) {
      // Round to the nearest integer
      int roundedPrice = currentTaskPrice.round();
      int remainder = roundedPrice % 10;

      if (remainder >= 5) {
        roundedPrice = ((roundedPrice / 10).ceil() * 10).toInt();
      } else {
        roundedPrice = ((roundedPrice / 10).floor() * 10).toInt();
      }
      return roundedPrice.toDouble();
    } else {
      int roundedPrice = currentTaskPrice.round();
      return ((roundedPrice / 10).floor() * 10).toDouble();
    }
  }

  Future<void> resetTask() async {
    currentTaskPrice = 0;
    totalDistance = 0;
    // routePositions.clear();
    isOnTask = false;
    lastRecordTime = null;
    currentVelocity = -1;
    startTime = null;

    //移除最上面那個 case
    cases.removeAt(0);
    notifyListeners();
  }

}