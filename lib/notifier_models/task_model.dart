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
    startTime = null;

    //移除最上面那個 case
    cases.removeAt(0);
    notifyListeners();
  }

}