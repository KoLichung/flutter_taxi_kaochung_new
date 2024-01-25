import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_taxi_chinghsien/models/user.dart';
import 'package:flutter_taxi_chinghsien/notifier_models/task_model.dart';
import 'package:flutter_taxi_chinghsien/pages/task/home_page.dart';
import 'package:flutter_taxi_chinghsien/pages/task/on_task_change_address_dialog.dart';
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
import 'on_task_passenger_off_dialog.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

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

    if(widget.theCase.caseState=='arrived'){
      _startButtonTimer();
      var taskModel = context.read<TaskModel>();
      _fetchTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        _fetchCaseState(userToken!, taskModel.cases.first.id!);
      });
    }else if(widget.theCase.caseState=='catched'){
      taskStatus = '載客中';
      isPassengerOnBoard = true;
      _startTaskTimer();
    }

  }

  Future<void> _startTaskTimer() async {
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool('isOnTask', true);
    var taskModel = context.read<TaskModel>();
    taskModel.startTime ??= DateTime.now();

    if (taskModel.isOnTask==false) {
      ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('開始計算路程！')));
      taskModel.isOnTask = true;
      bg.BackgroundGeolocation.setOdometer(0.0).catchError((error) {
        print('********** [resetOdometer] ERROR: $error');
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(SnackBar(content: Text('ERROR: $error')));
      });
    }

    _taskTimer ??= Timer.periodic(const Duration(seconds: 5), (timer) {
        // 5 秒計算一次時間
        var taskModel = context.read<TaskModel>();
        taskModel.setCurrentTaskPrice();
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
                          Text('${widget.theCase.carTeamName}'),
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

                                if(taskModel.currentTaskPrice==50.0){
                                  priceController.text = taskModel.startFee.toDouble().toString();
                                }else{
                                  priceController.text = taskModel.currentTaskPrice.toStringAsFixed(1);
                                }
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
                                      child: Icon(
                                        Icons.attach_money_rounded,
                                        color: Colors.black,
                                      ),
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
                )
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
        taskModel.resetTask();
        print('here on task finish');
        print(taskModel.cases);
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
              return OnTaskPassengerOffDialog(task_price:caseMoney ,before_left_money: map['before_left_money'],dispatch_fee: map['dispatch_fee'],after_left_money: map['after_left_money']);
            });

        if(taskModel.cases.isEmpty) {
          taskModel.isCanceled = false;
          taskModel.isOnTask = false;
          Navigator.popUntil(context, ModalRoute.withName('/main'));
        }
        // else{
        //   Navigator.pop(context);
        // }

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
    String path = ServerApi.PATH_GET_CASE_DETAIL;
    print(token);
    try {
      final queryParameters = {
        'case_id': caseId.toString(),
      };

      final response = await http.get(
        ServerApi.standard(path: path,queryParameters: queryParameters),
      );

      // print(response.body);

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      Case currentCase = Case.fromJson(map);
      print('case state ${currentCase.caseState}');
      if(currentCase.caseState=='canceled'){
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
        //回到首頁並帶參數
        taskModel.isCanceled = true;
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




