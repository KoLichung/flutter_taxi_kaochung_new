import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_taxi_chinghsien/notifier_models/task_model.dart';
import 'package:flutter_taxi_chinghsien/pages/task/current_task_report_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/serverApi.dart';
import '../../fake_customer_model.dart';
import '../../color.dart';
import 'package:provider/provider.dart';
import '../../models/case.dart';
import '../../notifier_models/user_model.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_small_elevated_button.dart';
import '../../widgets/custom_small_oulined_text.dart';
import 'new_passenger_dialog.dart';
import 'on_task.dart';
import 'package:map_launcher/map_launcher.dart';



class CurrentTask extends StatefulWidget {

  // final Case theCase;
  final bool isOpenCase;

  // const CurrentTask({Key? key,required this.theCase, required this.isOpenCase}) : super(key: key);
  const CurrentTask({Key? key, required this.isOpenCase}) : super(key: key);

  @override
  _CurrentTaskState createState() => _CurrentTaskState();
}

class _CurrentTaskState extends State<CurrentTask> {

  late Case theCase;

  String buttonText = '抵達乘客上車地點';
  bool isPassengerOnBoard = false;
  String taskStatus = '接客中';
  bool isNextTaskVisible = false;
  String? userToken;
  bool isRequesting = false;
  bool isAddressCopied = false;

  Timer? _fetchTimer;

  int initExpectedSeconds = 0;
  int remainSeconds = 0;
  DateTime? startTime;

  Timer? _remainTimer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // fetchNewTask();
    var userModel = context.read<UserModel>();
    userToken = userModel.token!;

    var taskModel = context.read<TaskModel>();
    if(taskModel.cases.isNotEmpty) {
      theCase = taskModel.cases.first;
    }else{
      Navigator.popUntil(context, ModalRoute.withName('/main'));
    }

    if(theCase.userExpectSecond!=0){
      initExpectedSeconds = theCase.userExpectSecond! + 120;
      remainSeconds = initExpectedSeconds;
      startTime ??= DateTime.parse(theCase.confirmTime!);
    }else{
      initExpectedSeconds = theCase.expectSecond! + 120;
      remainSeconds = initExpectedSeconds;
      startTime ??= DateTime.now();
    }

    _remainTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if(startTime!=null){
        DateTime currentTime = DateTime.now();
        int diffSecondsTotal = currentTime.difference(startTime!).inSeconds;
        remainSeconds = initExpectedSeconds -  diffSecondsTotal;
      }
      setState(() {});
    });

    _fetchTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      _fetchCaseState(userToken!, theCase.id!);
    });
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
                  // current task
                  Container(
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
                                  text: '目前任務：',
                                  style: const TextStyle(color: Colors.black87, fontSize: 18,),
                                  children: <TextSpan>[
                                    TextSpan(text: taskStatus,style: const TextStyle(color: AppColor.red,fontSize: 22,fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              (taskModel.cases.isNotEmpty)?
                              Text('${taskModel.cases.first.carTeamName}：${taskModel.cases.first.dispatcherNickName}')
                              :
                              Container(),
                            ],
                          ),
                          Container(
                            margin: const EdgeInsets.fromLTRB(0,10,0,0),
                            child: Row(
                              children: [
                                const Text('上車地：'),
                                CustomSmallElevatedButton(
                                    icon: const Icon(Icons.copy,size: 16,),
                                    title: '複製',
                                    color: isAddressCopied? Colors.grey : AppColor.primary,
                                    onPressed: ()async{
                                      if(!isAddressCopied){
                                        isAddressCopied = true;
                                      }
                                      await Clipboard.setData(ClipboardData(text:  taskModel.cases.first.onAddress!));
                                      ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('已複製上車地址')));
                                      setState(() {});
                                      // bool isGoogleMaps = await MapLauncher.isMapAvailable(MapType.google) ?? false;
                                      // print('onLat ${taskModel.cases.first.onLat} onLng ${taskModel.cases.first.onLng}');
                                      // try{
                                      //   if (isGoogleMaps == true) {
                                      //     await MapLauncher.showDirections(
                                      //       mapType: MapType.google,
                                      //       directionsMode: DirectionsMode.driving,
                                      //       destinationTitle: taskModel.cases.first.onAddress!,
                                      //       destination: Coords(
                                      //         double.parse(taskModel.cases.first.onLat!),
                                      //         double.parse(taskModel.cases.first.onLng!),
                                      //       ),
                                      //     );
                                      //   } else {
                                      //     await MapLauncher.showDirections(
                                      //       mapType: MapType.apple,
                                      //       directionsMode: DirectionsMode.driving,
                                      //       destinationTitle: taskModel.cases.first.onAddress!,
                                      //       destination: Coords(
                                      //         double.parse(taskModel.cases.first.onLat!),
                                      //         double.parse(taskModel.cases.first.onLng!),
                                      //       ),
                                      //     );
                                      //   }
                                      // }catch(e){
                                      //   print(e);
                                      // }
                                      // MapsLauncher.launchQuery(taskModel.cases.first.onAddress!);
                                    }),
                                const SizedBox(width: 5,),
                                (widget.isOpenCase == false)?CustomSmallElevatedButton(
                                    icon: const Icon(Icons.directions,size: 16,),
                                    title: '導航',
                                    color: isAddressCopied? Colors.grey : AppColor.primary,
                                    onPressed: ()async{
                                      bool isGoogleMaps = await MapLauncher.isMapAvailable(MapType.google) ?? false;
                                      print('onLat ${taskModel.cases.first.onLat} onLng ${taskModel.cases.first.onLng}');
                                      try{
                                        if (isGoogleMaps == true) {
                                          await MapLauncher.showDirections(
                                            mapType: MapType.google,
                                            directionsMode: DirectionsMode.driving,
                                            destinationTitle: taskModel.cases.first.onAddress!,
                                            destination: Coords(
                                              double.parse(taskModel.cases.first.onLat!),
                                              double.parse(taskModel.cases.first.onLng!),
                                            ),
                                          );
                                        } else {
                                          await MapLauncher.showDirections(
                                            mapType: MapType.apple,
                                            directionsMode: DirectionsMode.driving,
                                            destinationTitle: taskModel.cases.first.onAddress!,
                                            destination: Coords(
                                              double.parse(taskModel.cases.first.onLat!),
                                              double.parse(taskModel.cases.first.onLng!),
                                            ),
                                          );
                                        }
                                      }catch(e){
                                        print(e);
                                      }
                                      // MapsLauncher.launchQuery(taskModel.cases.first.onAddress!);
                                    }):Container()
                              ],
                            ),
                          ),
                          // Container(
                          //   margin: const EdgeInsets.fromLTRB(0,10,0,0),
                          //   child: Row(
                          //     children: [
                          //       const Text('乘客：'),
                          //       const SizedBox(width: 10),
                          //       CustomSmallElevatedButton(
                          //           icon: const Icon(Icons.call_outlined,size: 16,),
                          //           title: '電話',
                          //           color: AppColor.primary,
                          //           onPressed: (){
                          //             Uri uri = Uri.parse("tel://${taskModel.cases.first.customerPhone}");
                          //             launchUrl(uri);
                          //           })
                          //     ],
                          //   ),
                          // ),
                          // Container(
                          //   margin: const EdgeInsets.fromLTRB(0,0,0,10),
                          //   child: Row(
                          //     children: [
                          //       Text(taskModel.cases.first.customerName!),
                          //       const SizedBox(width: 10),
                          //       Text('${taskModel.cases.first.customerPhone}'),
                          //     ],
                          //   ),
                          // ),
                          (taskModel.cases.isNotEmpty)?
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${taskModel.cases.first.onAddress}'),
                              const SizedBox(height: 10,),
                              (taskModel.cases.first.offAddress!="")?Text('下車地：${taskModel.cases.first.offAddress}'):Container(),
                              (taskModel.cases.first.timeMemo!="")?Text('時間：${taskModel.cases.first.timeMemo}'):Container(),
                              (taskModel.cases.first.memo!="")?Text('備註：${taskModel.cases.first.memo}'):Container(),
                              Text(_getExpectTimeString(remainSeconds)),
                            ],
                          )
                              :
                          Container(),
                          const SizedBox(height: 10,),
                          CustomElevatedButton(
                            theHeight: 46,
                            onPressed: (){
                              if(!isRequesting){
                                _putCaseArrived(userToken!, taskModel.cases.first.id!);
                              }else{
                                ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('正在回傳資料，請稍候！')));
                              }
                            },
                            title: '抵達乘客上車地點',
                          )
                        ],
                      )
                  ),
                ],
              );
            }),
          ),
        )
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    if(_remainTimer!=null){
      print('cancel remain timer');
      _remainTimer!.cancel();
      _remainTimer = null;
    }
    if(_fetchTimer!=null){
      _fetchTimer!.cancel();
      _fetchTimer = null;
    }
  }

  //司機到了
  Future _putCaseArrived(String token, int caseId) async {
    isRequesting = true;
    ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('回傳資料中~')));
    String path = ServerApi.PATH_CASE_ARRIVE;

    try {
      // Map queryParameters = {
      //   'phone': user.phone,
      // };

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
        if(_fetchTimer!=null){
          _fetchTimer!.cancel();
          _fetchTimer = null;
        }
        var taskModel = context.read<TaskModel>();
        taskModel.cases.first.caseState = 'arrived';
        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => OnTask(theCase: taskModel.cases.first)));
        if(result == 'canceled'){
          Navigator.popUntil(context, ModalRoute.withName('/main'));
        }
        setState(() {});
      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('可能網路不佳，請再試一次！')));
      }
      isRequesting = false;
    } catch (e) {
      print(e);
      isRequesting = false;
      return "error";
    }
    // isRequesting = false;
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

        var taskModel = context.read<TaskModel>();
        taskModel.isCanceled = true;
        taskModel.resetTask();
        //回到首頁並帶參數
        print("pop to main");
        Navigator.popUntil(context, ModalRoute.withName('/main'));
      }

      setState(() {});

    } catch (e) {
      print(e);
    }
  }

  String _getExpectTimeString(int seconds){
    if (seconds >= 0){
      int integer = seconds ~/ 60;
      int remainder = seconds % 60;
      if (integer == 0){
        return '預估抵達時間：$remainder 秒';
      }else{
        return '預估抵達時間：$integer 分 $remainder 秒';
      }
    }else{
      seconds = -seconds;
      int integer = seconds ~/ 60;
      int remainder = seconds % 60;
      if (integer == 0){
        return '預估抵達時間：- $remainder 秒';
      }else {
        return '預估抵達時間：- $integer 分 $remainder 秒';
      }
    }
  }

}




