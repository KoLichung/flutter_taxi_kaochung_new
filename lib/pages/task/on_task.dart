import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_taxi_chinghsien/models/user.dart';
import 'package:flutter_taxi_chinghsien/notifier_models/task_model.dart';
import 'package:flutter_taxi_chinghsien/pages/task/home_page.dart';
import 'package:flutter_taxi_chinghsien/pages/task/on_task_change_address_dialog.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/serverApi.dart';
import '../../color.dart';
import '../../models/case.dart';
import '../../notifier_models/user_model.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_small_elevated_button.dart';
import 'current_task.dart';
import 'on_task_passenger_off_dialog.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import '../../services/route_export_service.dart';
import 'case_message_detail_page.dart';
import 'package:badges/badges.dart' as badges;

class OnTask extends StatefulWidget {

  final Case theCase;

  const OnTask({Key? key, required this.theCase}) : super(key: key);

  @override
  _OnTaskState createState() => _OnTaskState();
}

class _OnTaskState extends State<OnTask> {

  bool isPassengerOnBoard = false;

  String taskStatus = '接客中';

  bool isNextTaskVisible = false;
  bool isRequesting = false;
  bool isAddressCopied = false;
  int unreadMessageCount = 3; // 假數據：未讀消息數

  TextEditingController priceController = TextEditingController();
  Timer? _taskTimer;

  String offAddress = "下車地址";

  String? userToken;

  bool isTimerButtonEnable = false;
  Timer? _buttonTimer;
  int _buttonSeconds = 300;
  DateTime? buttonStartTime;
  
  DateTime? startTime;
  Timer? _fetchTimer;

  bool _isDialogShowing = false;

  Future<void> _startButtonTimer() async {

    buttonStartTime = DateTime.now();

    _buttonTimer ??= Timer.periodic(const Duration(seconds: 1), (_) async {

        if(buttonStartTime!=null){
          DateTime currentTime = DateTime.now();
          int diffSecondsTotal = currentTime.difference(buttonStartTime!).inSeconds;
          _buttonSeconds = 300 -  diffSecondsTotal;

          if (_buttonSeconds <= 0) {
            isTimerButtonEnable = true;
            _stopButtonTimer();
          }
        }

        setState(() {});
      });

  }

  Future<void> _stopButtonTimer() async {
    if (_buttonTimer!=null){
      _buttonTimer!.cancel();
      _buttonTimer = null;
    }
    _buttonSeconds = 300;
  }

  Future<void> _resetButtonTimer() async {
    _startButtonTimer();
    setState((){
      isTimerButtonEnable = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    // fetchNewTask();
    super.initState();
    var userModel = context.read<UserModel>();
    userToken = userModel.token!;

    offAddress = widget.theCase.offAddress!;

    print('init case state ${widget.theCase.caseState}');

    var taskModel = context.read<TaskModel>();
    print('print current task price ${taskModel.currentTaskPrice}');
    if(taskModel.currentTaskPrice < 10){
      print(taskModel.cases.first.feeTitle);
      if(taskModel.cases.isNotEmpty && taskModel.cases.first.feeTitle!=null && taskModel.cases.first.feeTitle!='') {
        taskModel.currentTaskPrice = taskModel.cases.first.feeStartFee!.toDouble();
        taskModel.startFee = taskModel.cases.first.feeStartFee!;
        taskModel.fifteenSecondFee = taskModel.cases.first.feeFifteenSecondFee!;
        taskModel.twoHundredMeterFee = taskModel.cases.first.feeTwoHundredMeterFee!;
      }else{
        taskModel.currentTaskPrice = 50;
        taskModel.startFee = 50;
        taskModel.fifteenSecondFee = 0.5;
        taskModel.twoHundredMeterFee = 4;
      }
    }

    if(widget.theCase.caseState=='arrived'){
      _startButtonTimer();
      var taskModel = context.read<TaskModel>();
      _fetchTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        _fetchCaseState(userToken!, taskModel.cases.first.id!);
      });
    }else if(widget.theCase.caseState=='catched'){
      taskStatus = '載客中';
      isPassengerOnBoard = true;
      print('need to start task timer');
      _startTaskTimer();

      var taskModel = context.read<TaskModel>();
      _fetchTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        _fetchCaseState(userToken!, taskModel.cases.first.id!);
      });
    }

  }

  Future<void> _startTaskTimer() async {
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool('isOnTask', true);
    var taskModel = context.read<TaskModel>();
    taskModel.startTime ??= DateTime.now();

    sleep(const Duration(seconds: 2));

    print('task model isOnTask ${taskModel.isOnTask}');
    if (taskModel.isOnTask==false) {
      Future.microtask(() {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('開始計算路程！')));
      });
      taskModel.isOnTask = true;

      // 保存第一筆位置數據
      try {
        var userModel = context.read<UserModel>();
        final position = userModel.currentPosition;
        print('[OnTask] 獲取初始位置: $position');

        if (position != null) {
          await RouteExportService.saveInitialLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            caseId: widget.theCase.id,
          );
          print(
              '[OnTask] 已保存初始位置: (${position.latitude}, ${position.longitude}) for case ID: ${widget.theCase.id}');
        } else {
          print('[OnTask] 警告：無法獲取初始位置來保存');
        }
      } catch (e) {
        print('[OnTask] 保存初始位置時發生錯誤: $e');
      }

      bg.BackgroundGeolocation.setOdometer(0.0).catchError((error) {
        print('********** [resetOdometer] ERROR: $error');
        Future.microtask(() {
          ScaffoldMessenger.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('ERROR: $error')));
        });
      });
    }

    print('current taskTimer $_taskTimer');
    _taskTimer ??= Timer.periodic(const Duration(seconds: 5), (timer) {
        // 5 秒計算一次時間
        var taskModel = context.read<TaskModel>();

        Future.microtask(() {
          taskModel.setCurrentTaskPrice(widget.theCase.carTeamId!);
        });
      });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    if(_taskTimer!=null){
      print('cancel onTask timer');
      _taskTimer!.cancel();
      _taskTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          // 消息圖標按鈕
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: unreadMessageCount > 0
                ? badges.Badge(
                    badgeContent: Text(
                      unreadMessageCount > 99 ? '99+' : unreadMessageCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    badgeStyle: const badges.BadgeStyle(
                      badgeColor: Colors.red,
                      padding: EdgeInsets.all(4),
                    ),
                    position: badges.BadgePosition.topEnd(top: 0, end: 0),
                    child: IconButton(
                      icon: const Icon(Icons.message),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CaseMessageDetailPage(
                              theCase: widget.theCase,
                              unreadCount: unreadMessageCount,
                            ),
                          ),
                        ).then((value) {
                          // 從消息頁返回後，可以更新未讀數
                          setState(() {
                            unreadMessageCount = 0; // 假設已讀
                          });
                        });
                      },
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.message),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CaseMessageDetailPage(
                            theCase: widget.theCase,
                            unreadCount: unreadMessageCount,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
          child:Consumer<TaskModel>(builder: (context, taskModel, child){
            return Column(
              children: [
                // Consumer<TaskModel>(builder: (context, taskModel, child){
                //   if (taskModel.routePositions.isNotEmpty) {
                //     return Text('目前的位置:${taskModel.routePositions.last.latitude.toStringAsFixed(3)}, ${taskModel.routePositions.last.longitude.toStringAsFixed(3)}');
                //   }else{
                //     return const Text("尚未 update 位置");
                //   }
                // }),
                Consumer<TaskModel>(builder: (context, taskModel, child){
                  return Text('目前的 公里數:${taskModel.totalDistance.toStringAsFixed(3)}km, 所有秒數：${taskModel.getSecondsTotal()}秒');
                }),
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColor.primary, width: 1),
                      borderRadius: BorderRadius.circular(3)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              text: '目前任務：',
                              style: const TextStyle(color: AppColor.primary, fontSize: 18,),
                              children: <TextSpan>[
                                TextSpan(text: taskStatus,style: const TextStyle(color: AppColor.red,fontSize: 22,fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Text('${widget.theCase.carTeamName}：${widget.theCase.dispatcherNickName}'),
                        ],
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(vertical: 8.0),
                      //   child: Text('${widget.theCase.customerName}   ${widget.theCase.customerPhone}'),
                      // ),
                      const SizedBox(height: 10,),
                      RichText(
                        text: TextSpan(
                          text: '上車地：',
                          style: const TextStyle(color: AppColor.primary, fontSize: 20,),
                          children: <TextSpan>[
                            TextSpan(text: widget.theCase.onAddress,style: const TextStyle(color: Colors.black87)),
                          ],
                        ),
                      ),//上車
                      RichText(
                        text: TextSpan(
                          text: '時間：',
                          style: const TextStyle(color: AppColor.primary, fontSize: 20,),
                          children: <TextSpan>[
                            TextSpan(text: widget.theCase.timeMemo,style: const TextStyle(color: Colors.black87)),
                          ],
                        ),
                      ),//上車
                      RichText(
                        text: TextSpan(
                          text: '備註：',
                          style: const TextStyle(color: AppColor.primary, fontSize: 20,),
                          children: <TextSpan>[
                            TextSpan(text: widget.theCase.memo,style: const TextStyle(color: Colors.black87)),
                          ],
                        ),
                      ),//上車
                      Row(
                        children: [
                          const Text("下車地：", style:  TextStyle(color: AppColor.primary, fontSize: 20,)),
                          const SizedBox(width: 10,),
                          CustomSmallElevatedButton(
                              icon: const Icon(Icons.copy,size: 16,),
                              title: '複製',
                              color: isAddressCopied? Colors.grey : AppColor.primary,
                              onPressed: () async {
                                if(!isAddressCopied){
                                  isAddressCopied = true;
                                }
                                await Clipboard.setData(ClipboardData(text:  offAddress));
                                ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('已複製下車地址')));
                                setState(() {});
                                // _launchMap(offAddress);
                                // MapsLauncher.launchQuery(offAddress);

                                // bool isGoogleMaps = await MapLauncher.isMapAvailable(MapType.google) ?? false;
                                // print('onLat ${taskModel.cases.first.offLat} onLng ${taskModel.cases.first.offLng}');
                                // try{
                                //   if (isGoogleMaps == true) {
                                //     await MapLauncher.showDirections(
                                //       mapType: MapType.google,
                                //       directionsMode: DirectionsMode.driving,
                                //       destinationTitle: taskModel.cases.first.onAddress!,
                                //       destination: Coords(
                                //         double.parse(taskModel.cases.first.offLat!),
                                //         double.parse(taskModel.cases.first.offLng!),
                                //       ),
                                //     );
                                //   } else {
                                //     await MapLauncher.showDirections(
                                //       mapType: MapType.apple,
                                //       directionsMode: DirectionsMode.driving,
                                //       destinationTitle: taskModel.cases.first.onAddress!,
                                //       destination: Coords(
                                //         double.parse(taskModel.cases.first.offLat!),
                                //         double.parse(taskModel.cases.first.offLng!),
                                //       ),
                                //     );
                                //   }
                                // }catch(e){
                                //   print(e);
                                // }

                              })
                        ],
                      ),
                      Text(offAddress, style: const TextStyle(color: Colors.black87,fontSize: 20)),
                      Row(
                        children: [
                          CustomSmallElevatedButton(
                              icon: const Icon(Icons.edit_outlined),
                              title: '修改下車地址',
                              color: AppColor.primary,
                              onPressed: ()async{
                                var data = await showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return OnTaskChangeAddressDialog();
                                    });
                                if(data!=null && data.toString()!=""){
                                  setState(() {
                                    offAddress = data.toString();
                                  });
                                }else{
                                  ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('下車地址不可為空白！')));
                                }
                              })
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                              margin: const EdgeInsets.fromLTRB(0,10,10,10),
                              height: 40,
                              width: 82,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1,),
                                borderRadius: BorderRadius.circular(4),),
                              child:
                              Consumer<TaskModel>(builder: (context, taskModel, child){
                                priceController.text = taskModel.currentTaskPrice.toStringAsFixed(0);
                                return TextFormField(
                                  validator: (String? value) {
                                    return (value != null ) ? '此為必填欄位' : null;
                                  },
                                  controller: priceController,
                                  onTap: (){
                                    if(_taskTimer!=null) {
                                      print('cancel onTask timer');
                                      _taskTimer!.cancel();
                                      _taskTimer = null;
                                    }
                                  },
                                  keyboardType: TextInputType.number,
                                  enabled: false,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: const InputDecoration(
                                    prefixIconConstraints: BoxConstraints(minWidth: 10, maxHeight: 20),
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.fromLTRB(4,2,2,0),
                                      // child: Icon(
                                      //   Icons.attach_money_rounded,
                                      //   color: Colors.black,
                                      // ),
                                    ),
                                    isDense: true,
                                    border: InputBorder.none,
                                  ),
                                );
                              })),
                        ],
                      ),
                      // const Text('(僅供參考，請依實際車資輸入)',style: TextStyle(color: AppColor.red),),
                      const SizedBox(height: 20),
                      !isPassengerOnBoard ?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomElevatedButton(
                            theHeight: 46,
                            onPressed: (){
                              _putCaseCatched(userToken!, widget.theCase.id!);
                            },
                            title: '乘客已上車'
                          ),
                          ElevatedButton(
                              onPressed: isTimerButtonEnable?
                                  (){
                                // here need to notify server
                                if(!isRequesting){
                                  _putCaseNotifyCustomer(userToken!, widget.theCase.id!);
                                }else{
                                  ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('回傳資料中~')));
                                }
                              }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: isTimerButtonEnable ? AppColor.primary : Colors.grey,
                                  elevation: 0
                              ),
                              child:
                                isTimerButtonEnable
                                    ?
                                const Text('乘客未上車\n05:00',style: TextStyle(fontSize: 20),textAlign: TextAlign.center,)
                                    :
                                Text('乘客未上車 \n ${_getButtonTimeString(_buttonSeconds!)}',style: TextStyle(fontSize: 20),textAlign: TextAlign.center,),
                          ),
                        ],
                      )
                          :
                      CustomElevatedButton(
                        theHeight: 46,
                        onPressed: (){
                          if(!isRequesting){
                            var userModel = context.read<UserModel>();
                            int intPrice = double.parse(priceController.text).toInt();
                            _putCaseFinish(userModel.token!, widget.theCase.id!, offAddress, intPrice);
                          }else{
                            ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('回傳資料中~')));
                          }
                        },
                        title: '乘客下車'
                      ),
                    ],
                  ),
                ),
                (taskModel.cases.length>1)?Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        border: Border.all(color: AppColor.primary, width: 1),
                        borderRadius: BorderRadius.circular(3)),
                    child:Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                text: '下一個任務：',
                                style: const TextStyle(color: AppColor.primary, fontSize: 18,),
                                children: <TextSpan>[
                                  TextSpan(text: '',style: const TextStyle(color: AppColor.red,fontSize: 22,fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Text('${taskModel.cases.last.carTeamName}')
                          ],
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(0,10,0,0),
                          child: Row(
                            children: [
                              Text('上車地：${taskModel.cases.last.onAddress}'),
                              const SizedBox(width: 5,),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10,),
                            (taskModel.cases.last.offAddress!="")?Text('下車地：${taskModel.cases.last.offAddress}'):Container(),
                            (taskModel.cases.last.timeMemo!="")?Text('時間：${taskModel.cases.last.timeMemo}'):Container(),
                            (taskModel.cases.last.memo!="")?Text('備註：${taskModel.cases.last.memo}'):Container(),
                          ],
                        )
                      ],
                    )
                ):Container(),
              ],
            );
          })
      ),
    )
    );
  }

  String _getButtonTimeString(int buttonSeconds){
    int minutes = buttonSeconds~/60;
    int seconds = buttonSeconds%60;
    if(seconds>=10){
      return '0$minutes:$seconds';
    }else{
      return '0$minutes:0$seconds';
    }
  }

  Future _putCaseNotifyCustomer(String token, int caseId) async {
    String path = ServerApi.PATH_CASE_NOTIFY_CUSTOMER;
    isRequesting = true;
    ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('回傳資料中~')));
    try {
      final queryParameters = {
        'case_id': caseId.toString(),
      };

      final response = await http.put(
        ServerApi.standard(path: path, queryParameters: queryParameters),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
        // body: jsonEncode(queryParameters)
      );

      print(response.body);

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      if(map['message']=='ok'){
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('已告知派單總機，請乘客趕快上車！')));
        _resetButtonTimer();
        var taskModel = context.read<TaskModel>();
        if(taskModel.startTime==null){
          _startTaskTimer();
        }
      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('可能網路不佳，請再試一次！')));
      }
      isRequesting = false;
    } catch (e) {
      print(e);
      isRequesting = false;
      return "error";
    }

  }

  Future _putCaseCatched(String token, int caseId) async {
    String path = ServerApi.PATH_CASE_CATCHED;
    isRequesting = true;
    ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('回傳資料中~')));
    try {
      final queryParameters = {
        'case_id': caseId.toString(),
      };

      final response = await http.put(
        ServerApi.standard(path: path, queryParameters: queryParameters),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
        // body: jsonEncode(queryParameters)
      );

      print(response.body);

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      if(map['message']=='ok'){
        // setState(() {});
        setState(() {
          taskStatus = '載客中';
          isPassengerOnBoard = true;
          _stopButtonTimer();
          _startTaskTimer();
        });
      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('可能網路不佳，請再試一次！')));
      }
      isRequesting = false;

    } catch (e) {
      print(e);
      isRequesting = false;
      return "error";
    }

  }

  Future _putCaseFinish(String token, int caseId, String offAddress, int caseMoney) async {
    String path = ServerApi.PATH_CASE_FINISH;
    isRequesting = true;
    ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('回傳資料中~')));
    try {
      final queryParameters = {
        'case_id': caseId.toString(),
      };

      Map bodyParams = {
        'off_address': offAddress,
        'case_money': caseMoney,
      };

      final response = await http.put(
        ServerApi.standard(path: path, queryParameters: queryParameters),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
        body: jsonEncode(bodyParams)
      );

      _printLongString(response.body);

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      if(map['message']=='ok'){
        var taskModel = context.read<TaskModel>();
        var userModel = context.read<UserModel>();
        
        // 在重置任務前匯出路線記錄
        print('[OnTask] 開始匯出路線記錄...');
        try {
          if (widget.theCase.id != null && userModel.user?.id != null) {
            final success = await RouteExportService.exportAndUploadRoute(
              caseId: widget.theCase.id!,
              userId: userModel.user!.id.toString(),
            );
            if (success) {
              print('[OnTask] 路線記錄上傳成功');
            } else {
              print('[OnTask] 路線記錄上傳失敗');
            }
          } else {
             print('[OnTask] 案件ID或用戶ID為空，無法匯出路線');
          }
        } catch (e) {
          print('[OnTask] 路線記錄上傳錯誤: $e');
        }
        
        taskModel.resetTask();
        print('here on task finish');
        // print(taskModel.cases);
        if(_taskTimer!=null){
          print('cancel onTask timer');
          _taskTimer!.cancel();
          _taskTimer = null;
        }
        if(_fetchTimer!=null){
          _fetchTimer!.cancel();
          _fetchTimer = null;
        }

        userModel.user!.leftMoney = map["after_left_money"];

        await showDialog<String>(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              return OnTaskPassengerOffDialog(task_price:map['case_money'] ,before_left_money: map['before_left_money'],dispatch_fee: map['dispatch_fee'],after_left_money: map['after_left_money']);
            });

        if(taskModel.cases.isEmpty) {
          taskModel.isCanceled = false;
          taskModel.isOnTask = false;
          Navigator.popUntil(context, ModalRoute.withName('/main'));
        }

        //回到首頁,再用 taskModel.cases.isEmpty 來判斷下一步
        Navigator.popUntil(context, ModalRoute.withName('/main'));

      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('可能網路不佳，請再試一次！')));
      }
      isRequesting = false;
    } catch (e) {
      print(e);
      isRequesting = false;
      return "error";
    }

  }

  Future _fetchCaseState(String token, int caseId) async {
    String path = ServerApi.PATH_GET_CASE_STATE_WITH_NEXT_CASE;
    print(token);
    try {
      final queryParameters = {
        'case_id': caseId.toString(),
      };

      final response = await http.get(
        ServerApi.standard(path: path,queryParameters: queryParameters),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'token $token'
        },
      );

      _printLongString(response.body);

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));

      String currentCaseState = map['current_case_state'];
      print('current case state $currentCaseState');

      if (map['confirmed_next_case'] != null){
        var taskModel = context.read<TaskModel>();
        if (taskModel.cases.length == 1){
          Case confirmedCase = Case.fromJson(map['confirmed_next_case']);
          taskModel.cases.add(confirmedCase);
        }
      }

      if (map['query_next_case'] != null){
        Case nextCase = Case.fromJson(map['query_next_case']);

        DateTime dispatchTime = nextCase.dispatchTime!;
        DateTime now = DateTime.now();
        int leftSecs = 18 - now.difference(dispatchTime).inSeconds;

        print(nextCase);
        // 彈出視窗~

        if (_isDialogShowing == false && leftSecs >= 1){
          _isDialogShowing = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              var userModel = context.read<UserModel>();
              return MyDialog(currentPosition: userModel.currentPosition!, theNextCase: nextCase);
            },
          ).then((value) => {
            _isDialogShowing = value
          });
        }

      }

      if(currentCaseState == 'canceled'){
        if(_fetchTimer!=null){
          _fetchTimer!.cancel();
          _fetchTimer = null;
        }
        if(_taskTimer!=null){
          _taskTimer!.cancel();
          _taskTimer = null;
        }
        if (_buttonTimer!=null){
          _buttonTimer!.cancel();
          _buttonTimer = null;
        }
        var taskModel = context.read<TaskModel>();
        taskModel.resetTask();
        // resetTask 只是移除最先放入的那個！

        //回到首頁並帶參數
        if(taskModel.cases.isEmpty) {
          taskModel.isCanceled = true;
          taskModel.isOnTask = false;
        }

        //回到首頁,再用 taskModel.cases.isEmpty 來判斷下一步
        Navigator.popUntil(context, ModalRoute.withName('/main'));
      }

      setState(() {});

    } catch (e) {
      print(e);
    }
  }

  void _printLongString(String text) {
    final RegExp pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((RegExpMatch match) => print(match.group(0)));
  }

  // void _launchMap(String address) async {
  //   String query = Uri.encodeComponent(address);
  //   String googleUrl = "https://www.google.com/maps/search/?api=1&query=$query";
  //   Uri googleUri = Uri.parse(googleUrl);
  //
  //   if (await canLaunchUrl(googleUri)) {
  //     await launchUrl(googleUri);
  //   }
  // }

}

class MyDialog extends StatefulWidget {
  final Case theNextCase;
  final Position currentPosition;

  const MyDialog({Key? key, required this.theNextCase, required this.currentPosition}) : super(key: key);

  @override
  _MyDialogState createState() => _MyDialogState();
}

class _MyDialogState extends State<MyDialog> {
  late Timer _timer;
  int _taskWaitingTime = 17;
  bool isResponseConfirming = false;

  @override
  void initState() {
    super.initState();
    // 定时器，每秒更新一次计数器
    DateTime dispatchTime = widget.theNextCase.dispatchTime!;
    print('dispatch time $dispatchTime');
    DateTime now = DateTime.now();
    _taskWaitingTime = 18 - now.difference(dispatchTime).inSeconds;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _taskWaitingTime--;

        if(_taskWaitingTime <= 0){
          Navigator.pop(context, false);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        height: 300,
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
            Text('${widget.theNextCase.carTeamName}'),
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
              Text('距離 ${_getDistance(widget.theNextCase, widget.currentPosition)}'),
            ],),
            Text('預計行車時間：${_getExpectTimeString(widget.theNextCase.expectSecond! + 120)}'),
            Text('上車地：${widget.theNextCase.onAddress}'),
            // (myCases[i].offAddress!="")?Text('下車地：${myCases[i].offAddress}'):Container(),
            (widget.theNextCase.timeMemo!="")?Text('時間：${widget.theNextCase.timeMemo}'):Container(),
            (widget.theNextCase.memo!="")?Text('備註：${widget.theNextCase.memo}'):Container(),
            const SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CustomElevatedButton(
                        theHeight: 46,
                        onPressed: (){
                          if (isResponseConfirming == false){
                            isResponseConfirming = true;
                            var userModel = context.read<UserModel>();
                            _putCaseConfirm(userModel.token!, widget.theNextCase);
                          }
                        },
                        title: '接單'),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CustomElevatedButton(
                        theHeight: 46,
                        onPressed: (){
                          if (isResponseConfirming == false){
                            isResponseConfirming = true;
                            var userModel = context.read<UserModel>();
                            _putCaseRefuse(userModel.token!, widget.theNextCase);
                          }

                        },
                        title: '拒絕',
                        color: AppColor.red),
                  ),
                ),
              ],
            ),
          ],),)
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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

  String _getExpectTimeString(int seconds){
    int integer = seconds ~/ 60;
    int remainder = seconds % 60;
    if (integer == 0){
      return '預估時間 $remainder 秒';
    }else{
      return '預估時間 $integer 分 $remainder 秒';
    }
  }

  Future _putCaseConfirm(String token, Case theCase) async {
    print("case confirm");
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

      // _printLongString(response.body);

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));

      if(map['message']=='ok'){
        _timer.cancel();
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('已順利接到下一單！')));

      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('系統問題，未順利接單！')));
      }
      isResponseConfirming = false;
      Navigator.pop(context, false);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('系統問題，未順利接單！')));
      // return "error";
      isResponseConfirming = false;
      Navigator.pop(context, false);
    }
  }

  Future _putCaseRefuse(String token, Case theCase) async {
    print("case refuse");
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
        _timer.cancel();
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('您拒絕了這個單子！')));
      }

      Navigator.pop(context, false);
    } catch (e) {
      print(e);
      Navigator.pop(context, false);
    }
  }

  void _printLongString(String text) {
    final RegExp pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((RegExpMatch match) => print(match.group(0)));
  }
}





