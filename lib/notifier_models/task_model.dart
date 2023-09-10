import 'package:flutter/cupertino.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import '../models/case.dart';

class TaskModel extends ChangeNotifier {

  List<Case> cases = [];

  bool isCanceled = false;
  bool isOnTask = false;
  // List<Position> routePositions = [];
  double currentTaskPrice = 50.0;
  double totalDistance = 0;
  // int secondTotal = 0;

  DateTime? lastRecordTime;
  double currentVelocity = -1;

  DateTime? startTime;

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

  Future<void> setCurrentTaskPrice() async {
    int secondTotal = 0;

    if(startTime!=null){
      DateTime currentTime = DateTime.now();
      secondTotal = currentTime.difference(startTime!).inSeconds;
    }

    if(totalDistance >= 0.01){
      int totalDistanceInMeter = (totalDistance * 1000).floor();
      int times = totalDistanceInMeter ~/ 5;
      currentTaskPrice = 50.0 + times * 0.1;
    }else{
      currentTaskPrice = 50.0;
    }

    int times = secondTotal~/15;
    currentTaskPrice = currentTaskPrice +  times*0.5;

    print('current velocity $currentVelocity');
    print('total distance $totalDistance');
    print('startTime $startTime');
    print('total second $secondTotal');
    notifyListeners();
  }

  Future<void> resetTask() async {
    currentTaskPrice = 50.0;
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