import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_taxi_chinghsien/notifier_models/task_model.dart';
import 'package:flutter_taxi_chinghsien/pages/task/cancel_dialog.dart';
import 'package:flutter_taxi_chinghsien/pages/task/disclosure_dialog.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/serverApi.dart';
import '../../color.dart';
import '../../models/case.dart';
import '../../notifier_models/user_model.dart';
import '../../widgets/custom_elevated_button.dart';
import 'current_task.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

import 'on_task.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  bool _isOnlining = false;
  Timer? _timer;
  int timerPeriod = 3;

  late List<Case> myCases = <Case>[];

  // final LocationSettings locationSettings = const LocationSettings(
  //   accuracy: LocationAccuracy.best,
  //   distanceFilter: 10,
  // );

  Timer? _taskTimer;
  int _taskWaitingTime = 17;

  bool isRefusing = false;
  bool isCaseConfirming = false;

  // int _violation_time = 0;
  // DateTime? _penalty_datetime;

  void _startTaskTimer() {
    DateTime dispatchTime = myCases.first.dispatchTime!;
    print('dispatch time $dispatchTime');

    const oneSec = Duration(seconds: 1);
    _taskTimer = Timer.periodic(oneSec, (Timer timer) {
        DateTime now = DateTime.now();
        _taskWaitingTime = 18 - now.difference(dispatchTime).inSeconds;
        print('_taskWaitingTime $_taskWaitingTime');
        if(_taskWaitingTime <= 0){
          myCases.clear();
          _taskWaitingTime = 0;
          if(_taskTimer!=null) {
            print('cancel task timer');
            _taskTimer!.cancel();
            _taskTimer=null;
          }
        }
        setState(() {});
      },
    );
  }

  @override
  void initState(){
    super.initState();
    // _handlePermission();
    _getLatestAppVersion();
    var userModel = context.read<UserModel>();

    if(userModel.currentAppVersion == null){
      _initPackageInfo();
    }

    if(userModel.deviceId==null){
      print('get device info');
      _getDeviceInfo();
    }else{
      print('post fcm device');
      _httpPostFCMDevice();
    }

    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      print('[location] - $location');

      var userModel = context.read<UserModel>();
      userModel.currentPosition = Position(longitude: location.coords.longitude, latitude: location.coords.latitude, timestamp: DateTime.now(), accuracy: location.coords.accuracy, altitude: location.coords.altitude, heading: location.coords.heading, speed: location.coords.speed, speedAccuracy: location.coords.accuracy);


      if(userModel.isOnline){
        _fetchUpdateLatLng(userModel.token!, userModel.currentPosition!.latitude, userModel.currentPosition!.longitude);
      }

      var taskModel = context.read<TaskModel>();
      if(taskModel.isOnTask){
        taskModel.totalDistance = location.odometer/1000.0;
      }
    });

    bg.BackgroundGeolocation.ready(bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 10.0,
        stopOnTerminate: true,
        startOnBoot: true,
        debug: false,
        stationaryRadius: 25,
        logLevel: bg.Config.LOG_LEVEL_VERBOSE,
        //add 2023/06/24 for ios
        preventSuspend: true,
        heartbeatInterval: 60,
        // ===
        backgroundPermissionRationale: bg.PermissionRationale(
          title: "允許 {applicationName} 在背景程式使用位置資訊？",
          message: "為了取得位置並提供您案件資訊，請允許在背景使用您的位置。",
          positiveAction: "允許",
          negativeAction: "取消"
        )
    )).then((bg.State state) async {
      if (!state.enabled) {
        if(userModel.platformType=='android') {
          await showDialog<String>(
              context: context,
              builder: (BuildContext context) {
                return DisclosureDialog();}
          );
          bg.BackgroundGeolocation.start();
        }else{
          bg.BackgroundGeolocation.start();
        }
      }
    });

    if(userModel.isOnline && userModel.user!.isPassed!){
        _putUpdateOnlineState(userModel.token!, true);
        print('start timer');
        _timer = Timer.periodic(Duration(seconds: timerPeriod), (timer) {
          // print('Hello world, timer: $timer.tick');
          _fetchCases(userModel.token!);
        });
        bg.BackgroundGeolocation.start();
    }

  }

  @override
  void dispose() {
    super.dispose();
    if(_timer!=null){
      print('cancel timer');
      _timer!.cancel();
      _timer = null;
    }
    if(_taskTimer!=null) {
      print('cancel task timer');
      _taskTimer!.cancel();
      _taskTimer=null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // _showNotification();
    // _checkLocationPermission();

    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                      image:AssetImage('images/logo.png',),
                      fit:BoxFit.scaleDown),),
                height: 25,
                width: 40,
              ),
              // Icon(FontAwesomeIcons.taxi),
              const SizedBox(width: 10,),
              const Text('24h派車'),
            ],
          ),
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(130.0),
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(width: 1.0, color: Colors.grey.shade300),
                    )
                ),
                child: Consumer<UserModel>(builder: (context, userModel, child) =>
                    Column(
                      children: [
                        const SizedBox(height: 10,),
                        userModel.isOnline? statusOnlineButton() : statusOfflineButton(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('我的狀態：'),
                            userModel.isOnline? const Text('上線中') : const Text('休息中'),
                            const SizedBox(width: 10,),
                            const Text('目前餘額：'),
                            Text(userModel.user!.leftMoney.toString()),
                          ],
                        ),
                        (userModel.user!.violation_time!<5)?
                        Text('違規次數：${userModel.user!.violation_time!}',style: TextStyle(color: Colors.redAccent),)
                        :
                        Text('處罰：${DateFormat('yyyy/MM/dd HH:mm').format(userModel.user!.penalty_datetime!.add(Duration(hours: 8)))} 後可上線',style: TextStyle(color: Colors.redAccent),)
                      ],
                    ),
                ),
              )
          ),
        ),
        body: Consumer<UserModel>(builder: (context, userModel, child) =>
        userModel.isOnline? checkIsTasks() : offlineScene(),
        ),
      )
    );
  }

  statusOnlineButton(){
    return ElevatedButton(
        style: ElevatedButton.styleFrom(primary: AppColor.red,elevation: 0),
        child: const Text('點我休息'),
        onPressed: () async {
          actionOffline();
        },
    );
  }

  void actionOffline(){
    var userModel = context.read<UserModel>();
    userModel.resetPositionParams();

    if(_timer!=null){
      print('cancel timer');
      _timer!.cancel();
      _timer = null;
    }

    bg.BackgroundGeolocation.stop();

    _putUpdateOnlineState(userModel.token!, false);
  }

  statusOfflineButton(){
    return ElevatedButton(
        style: ElevatedButton.styleFrom(primary: AppColor.green,elevation: 0),
        child: const Text('點我上線'),
        onPressed: () async {

          if(_isOnlining == true){
            ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('正在上線中~~')));
          }else{
            _isOnlining = true;
            ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('上線中~~')));

            var userModel = context.read<UserModel>();

            if(userModel.user!.isPassed!) {
              final result = await _putUpdateOnlineState(userModel.token!, true);
              // result ok 為成功上線
              if(result=="ok"){
                print('start timer');
                _timer = Timer.periodic(Duration(seconds: timerPeriod), (timer) {
                  // print('Hello world, timer: $timer.tick');
                  _fetchCases(userModel.token!);
                });
                bg.BackgroundGeolocation.start();
                _getCurrentPosition();
              }else{
                // print('in penalty or no money');
                ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('處罰中 或 需充值~無法上線~')));
              }
            }else{
              ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('未通過審核！')));
            }

          }
        },
    );
  }

  checkIsTasks(){
    var userModel = context.read<UserModel>();
    if (myCases.isEmpty || !userModel.user!.isPassed!){
      return onCallScene(userModel.user!.isPassed!);
    } else {
      if(_taskWaitingTime==0 || _taskWaitingTime==-1){
        return onCallScene(userModel.user!.isPassed!);
      }
      return getTaskList(userModel.currentPosition!);
    }
  }

  onCallScene(bool isPassed){
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 100),
            Column(
              children: [
                const Icon(FontAwesomeIcons.mugHot,size: 28,),
                const SizedBox(height: 5,),
                const Text('暫時沒有任務'),
                (!isPassed)? const Text('(尚未通過審核，無法接任務！)'):Container(),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );

  }

  getTaskList(Position currentPosition){
    return ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: myCases.length,
            itemBuilder: (BuildContext context,int i){
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 18,vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14,vertical: 14),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColor.primary, width: 1),
                    borderRadius: BorderRadius.circular(3)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text('空派任務：${myCases[i].shipState!}'),
                    Center(child: Text('倒數：$_taskWaitingTime 秒')),
                    Text('${myCases[i].carTeamName}'),
                    Row(children: [
                      Container(
                        margin:const EdgeInsets.fromLTRB(0,4,8,0),
                        padding:const EdgeInsets.symmetric(vertical: 2,horizontal: 8),
                        decoration:BoxDecoration(
                          border: Border.all(color: AppColor.primary, width: 1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text('客戶',style: TextStyle(color: AppColor.primary),),
                      ),
                      if(currentPosition!=null)Text('距離 ${_getDistance(myCases[i], currentPosition)}'),
                    ],),
                    Text('預計行車時間：${_getExpectTimeString(myCases[i].expectSecond! + 120)}'),
                    Text('上車地：${myCases[i].onAddress}'),
                    // (myCases[i].offAddress!="")?Text('下車地：${myCases[i].offAddress}'):Container(),
                    (myCases[i].timeMemo!="")?Text('時間：${myCases[i].timeMemo}'):Container(),
                    (myCases[i].memo!="")?Text('備註：${myCases[i].memo}'):Container(),
                    const SizedBox(height: 10,),
                    CustomElevatedButton(
                      theHeight: 46,
                        onPressed: (){
                          var userModel = context.read<UserModel>();
                          _putCaseConfirm(userModel.token!, myCases[i]);
                          myCases.removeAt(i);
                          // ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('接單中~~')));
                        },
                        title: '接單'),
                    CustomElevatedButton(
                      theHeight: 46,
                      onPressed: (){
                        var userModel = context.read<UserModel>();
                        _putCaseRefuse(userModel.token!, myCases[i]);
                        myCases.removeAt(i);
                        isRefusing = true;
                      },
                      title: '拒絕',
                      color: AppColor.red)
                  ],),);
            });
  }

  String _getExpectTimeString(int seconds){
    int integer = seconds ~/ 60;
    int remainder = seconds % 60;
    if (integer == 0){
      return '預估時間 $remainder 秒';
    }else{
      return '預估時間 $integer 分 $remainder 秒';
    }
  }

  String _getDistance(Case theCase, Position currentPosition){
    double distance = Geolocator.distanceBetween(currentPosition.latitude, currentPosition.longitude, double.parse(theCase.onLat!), double.parse(theCase.onLng!));
    if(distance > 1000){
      distance = distance / 1000;
      return distance.toStringAsFixed(2) + " 公里";
    }else{
      return distance.toStringAsFixed(0) + " 公尺";
    }
  }

  offlineScene(){
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 100),
            Column(
              children: const [
                Icon(Icons.bolt_outlined,size: 40,),
                Text('您現在休息中~'),
              ],),
            const SizedBox(height: 50),

          ],
        ),
      ),
    );
  }

  Future<AudioPlayer> _playLocalAsset() async {
    AudioCache cache = AudioCache();
    //At the next line, DO NOT pass the entire reference such as assets/yes.mp3. This will not work.
    //Just pass the file name only.
    return await cache.play("ding_dong.mp3");
  }

  Future<AudioPlayer> _playCancelAsset() async {
    AudioCache cache = AudioCache();
    //At the next line, DO NOT pass the entire reference such as assets/yes.mp3. This will not work.
    //Just pass the file name only.
    return await cache.play("cancel_2.mp3");
  }

  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    var userModel = context.read<UserModel>();

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (userModel.platformType == 'ios' && permission != LocationPermission.denied && permission != LocationPermission.always){
      showDialog<void>(context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('位置使用權限'),
            content: SingleChildScrollView(
              child: ListBody(
                children: const <Widget>[
                  Text('App 需要知道您的位置，以告訴您附近案件。'),
                  Text('請將權限調整為「永遠」'),
                  Text('This app needs access to location to notify your nearby case.'),
                  Text('Please change permission to "Always"'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('確定'),
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (userModel.platformType == 'ios' && permission != LocationPermission.always){
        showDialog<void>(context: context,
          barrierDismissible: false, // user must tap button!
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('位置使用權限'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: const <Widget>[
                    Text('App 需要知道您的位置，以告訴您附近案件。'),
                    Text('請將權限調整為「永遠」'),
                    Text('This app needs access to location to notify your nearby case.'),
                    Text('Please change permission to "Always"'),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('確定'),
                  onPressed: () async {
                    await Geolocator.openLocationSettings();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handlePermission();

    if (!hasPermission) {
      // return;
    }

    print('getting position');
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    var userModel = context.read<UserModel>();
    if(userModel.isOnline){
      userModel.currentPosition = position;
      _fetchUpdateLatLng(userModel.token!, userModel.currentPosition!.latitude, userModel.currentPosition!.longitude);
    }

  }

  Future _fetchUpdateLatLng(String token, double lat, double lng) async {
    String path = ServerApi.PATH_UPDATE_LAT_LNG;
    final queryParameters = {
      'lat': lat.toString(),
      'lng': lng.toString(),
    };

    try {
      final response = await http.get(
        ServerApi.standard(path: path, queryParameters: queryParameters),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'token $token'
        },
      );

      print(response.body);

      // List body = json.decode(utf8.decode(response.body.runes.toList()));
      // print(body);

    } catch (e) {
      print(e);
    }
  }

  Future _fetchCases(String token) async {
    String path = ServerApi.PATH_GET_CASES;
    print(token);
    try {
      final response = await http.get(
        ServerApi.standard(path: path),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'token $token'
        },
      );

      // print(response.body);
      _printLongString(response.body);

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      List body = map["cases"];

      var userModel = context.read<UserModel>();
      userModel.user!.leftMoney = map["left_money"];
      userModel.user!.violation_time = map["violation_time"];
      if (map["penalty_datetime"] != null){
        userModel.user!.penalty_datetime = DateTime.parse(map["penalty_datetime"]);
        // print('_penalty_datetime ${userModel.user!.penalty_datetime}');
      }else{
        userModel.user!.penalty_datetime = null;
      }

      // 如果 left money < -100, 自動下線
      if(map["left_money"]<= -100 || userModel.user!.violation_time == 5){
        actionOffline();
      }else{
        List<Case> cases = body.map((value) => Case.fromJson(value)).toList();
        if(cases.isNotEmpty && cases.first.caseState!='dispatching'){
          // 這邊要跳頁,並解除 timer (這邊跟 putConfirm 很像, code 沒有整理)
          print('need push to CurrentTask');

          var taskModel = context.read<TaskModel>();
          taskModel.cases.clear();
          taskModel.cases.add(cases.first);
          if(cases.first.caseState=='way_to_catch'){
            if(!isCaseConfirming) {
              print('hererererererererer');
              pushToCurrentTask(cases.first);
            }
          }else{
            pushToOnTask(cases.first);
          }

        }else{
          if(myCases.isEmpty && cases.isNotEmpty){
            if(!isRefusing){
              _playLocalAsset();
            }
          }

          // 如果拒絕中, 跳過更新一次！
          if(!isRefusing) {
            myCases = cases;
          }else{
            isRefusing = false;
          }

          print('_taskTimer $_taskTimer');

          if(myCases.isNotEmpty && _taskTimer==null){
            print('start timer');
            // int currentTime = myCases.first.countdownSecond!;
            // if(currentTime==18){
            //   currentTime = 17;
            // }
            _startTaskTimer();
          }
        }

      }

      if(myCases.isEmpty) {
        setState(() {});
      }

    } catch (e) {
      print(e);
    }
  }

  pushToCurrentTask(Case theCase) async {
    if(_timer!=null){
      print('cancel timer');
      _timer!.cancel();
      _timer = null;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (context) =>  CurrentTask(theCase: theCase)));
    var taskModel = context.read<TaskModel>();

    if(taskModel.isCanceled == true){
      myCases.clear();
      showDialog<String>(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return const CancelDialog();
          });
    }

    setState(() {
      myCases.clear();
    });

    var userModel = context.read<UserModel>();
    if (userModel.isOnline && _timer == null){
      print('start timer');
      _timer = Timer.periodic(Duration(seconds: timerPeriod), (timer) {
        _fetchCases(userModel.token!);
      });
    }
  }

  pushToOnTask(Case theCase) async {
    if(_timer!=null){
      print('cancel timer');
      _timer!.cancel();
      _timer = null;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (context) => OnTask(theCase: theCase)));
    var taskModel = context.read<TaskModel>();
    if(taskModel.isCanceled==true){
      myCases.clear();
      _playCancelAsset();
      showDialog<String>(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return const CancelDialog();
          });
    }

    setState(() {
      myCases.clear();
    });

    var userModel = context.read<UserModel>();
    if (userModel.isOnline && _timer == null){
      print('start timer');
      _timer = Timer.periodic(Duration(seconds: timerPeriod), (timer) {
        _fetchCases(userModel.token!);
      });
    }
  }

  Future _putCaseConfirm(String token, Case theCase) async {
    print("case confirm");
    isCaseConfirming = true;
    String path = ServerApi.PATH_CASE_CONFIREM;

    try {
      final queryParameters = {
        'case_id': theCase.id!.toString(),
      };

      final response = await http.put(
          ServerApi.standard(path: path, queryParameters: queryParameters),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Token $token',
          },
      );

      _printLongString(response.body);

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));

      if(map['message']=='ok'){
        if(_timer!=null){
          print('cancel timer');
          _timer!.cancel();
          _timer = null;
        }
        if(_taskTimer!=null) {
          print('cancel task timer');
          _taskTimer!.cancel();
          _taskTimer=null;
        }

        var taskModel = context.read<TaskModel>();
        theCase.caseState='way_to_catch';
        taskModel.cases.clear();
        taskModel.cases.add(theCase);

        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => CurrentTask(theCase: theCase)));
        isCaseConfirming = false;

        print(result);
        if(taskModel.isCanceled == true){
          myCases.clear();
          _playCancelAsset();
          showDialog<String>(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) {
                return const CancelDialog();
              });
        }

        setState(() {
          myCases.clear();
        });

        var userModel = context.read<UserModel>();
        if (userModel.isOnline && _timer == null){
          print('start timer');
          _timer = Timer.periodic(Duration(seconds: timerPeriod), (timer) {
            _fetchCases(userModel.token!);
          });
        }
      }else{
        isCaseConfirming = false;
        if(_taskTimer!=null) {
          print('cancel task timer');
          _taskTimer!.cancel();
          _taskTimer=null;
        }
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('這個單可能已經被接走！')));
      }

      setState(() {});
    } catch (e) {
      print(e);
      isCaseConfirming = false;
      if(_taskTimer!=null) {
        print('cancel task timer');
        _taskTimer!.cancel();
        _taskTimer=null;
      }
      ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('這個單可能已經被接走！')));
      // return "error";
    }
  }

  Future _putCaseRefuse(String token, Case theCase) async {
    print("case confirm");

    String path = ServerApi.PATH_CASE_REFUSE;

    try {
      final queryParameters = {
        'case_id': theCase.id!.toString(),
      };

      final response = await http.put(
        ServerApi.standard(path: path, queryParameters: queryParameters),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
      );

      _printLongString(response.body);

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));

      if(map['message']=='ok'){
        if(_taskTimer!=null) {
          print('cancel task timer');
          _taskTimer!.cancel();
          _taskTimer=null;
        }
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('您拒絕了這個單子！')));
      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('這個單可能已經被接走！')));
      }

      setState(() {});
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('這個單可能已經被接走！')));
      // return "error";
    }
  }

  Future _putUpdateOnlineState(String token, bool isOnline) async{
    String path = ServerApi.PATH_UPDATE_ONLINE_STATE;

    try {

      Map bodyParameters = {
        'is_online': isOnline.toString(),
      };

      final response = await http.put(
        ServerApi.standard(path: path),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
          body: jsonEncode(bodyParameters)
      );

      _isOnlining = false;

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      if(map['message']=='ok'){
        print("success update online state!");
        if(isOnline){
          // save to prefs
          print('set isOnline true to prefs');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isOnline', true);

          ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('已上線！')));
          var userModel = context.read<UserModel>();
          setState(() {
            userModel.isOnline = true;
          });
          return "ok";
        }else{
          // save to prefs
          print('set isOnline false to prefs');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isOnline', false);

          ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('已下線！')));
          var userModel = context.read<UserModel>();
          setState(() {
            userModel.isOnline = false;
          });
          return "ok";
        }
      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('無法上線，請充值！')));
        return "error";
      }
    } catch (e) {
      print(e);
      return "error";
    }
  }

  Future _getDeviceInfo() async {
    var userModel = context.read<UserModel>();
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) { // import 'dart:io'
      var iosDeviceInfo = await deviceInfo.iosInfo;
      String deviceID = iosDeviceInfo.identifierForVendor!;
      print(deviceID);
      userModel.deviceId = deviceID;
      userModel.platformType = 'ios';
      // setState(() {});
      _httpPostFCMDevice();
    } else {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      String deviceID =  androidDeviceInfo.device;
      print(deviceID);
      userModel.deviceId = deviceID;
      userModel.platformType = 'android';
      // setState(() {});
      _httpPostFCMDevice();
    }
  }

  Future<void> _initPackageInfo() async {
    //抓取當前 app 版本
    var userModel = context.read<UserModel>();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    userModel.setCurrentAppVersion(packageInfo.version);
    userModel.setCurrentAppVersionNumber(int.parse(packageInfo.buildNumber));
    print('----------');
    print(userModel.currentAppVersion);
    print(userModel.currentAppVersionNumber);
    print('----------');
  }

  Future<void> _httpPostFCMDevice() async {
    print("postFCMDevice");
    String path = ServerApi.PATH_REGISTER_DEVICE;
    var userModel = context.read<UserModel>();

    if(userModel.fcmToken==null){
      await Future.delayed(const Duration(seconds: 5));
    }

    try {
      Map queryParameters = {
        'registration_id': userModel.fcmToken,
        'device_id': userModel.deviceId,
        'type': userModel.platformType,
      };

      print('here to post fcm');
      print(userModel.fcmToken);
      print(userModel.deviceId);
      print(userModel.platformType);
      print(userModel.token);

      if(userModel.fcmToken!=null) {
        final response = await http.post(ServerApi.standard(path: path),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Token ${userModel.token!}',
          },
          body: jsonEncode(queryParameters),
        );
        print(response.body);
      }
    }catch(e){
      print(e);
    }
  }

  Future _getLatestAppVersion () async {
    String path = ServerApi.PATH_GET_CURRENT_VERSION;
    try {
      final response = await http.get(ServerApi.standard(path: path));
      if (response.statusCode == 200){
        Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));

        var userModel = context.read<UserModel>();
        if(userModel.platformType!=null && userModel.currentAppVersion != null){
          if(userModel.platformType=='ios' && userModel.currentAppVersionNumber! < int.parse(map['ios'])){
            return showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) => AlertDialog(
                contentPadding: const EdgeInsets.all(20),
                content: const Text('有新的 App 版本，請立即更新'),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                    child: const Text('前往更新'),
                    onPressed: ()async{
                      String app= 'appStore url';
                      Uri url = Uri.parse(app);
                      if (!await launchUrl(url)) {
                        throw 'Could not launch $url';
                      }
                    },
                  ),
                ],
              ),
            );
          }else if (userModel.platformType=='android' && userModel.currentAppVersionNumber! < int.parse(map['android'])){
            return showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) => AlertDialog(
                contentPadding: const EdgeInsets.all(20),
                content: const Text('有新的 App 版本，請立即更新'),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                    child: const Text('前往更新'),
                    onPressed: ()async{
                      String app= 'google play url';
                      Uri url = Uri.parse(app);
                      if (!await launchUrl(url)) {
                        throw 'Could not launch $url';
                      }
                    },
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  void _printLongString(String text) {
    final RegExp pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((RegExpMatch match) => print(match.group(0)));
  }

}



