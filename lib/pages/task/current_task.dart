import 'dart:async';
import 'dart:convert';
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

  const CurrentTask({Key? key}) : super(key: key);

  @override
  _CurrentTaskState createState() => _CurrentTaskState();
}

class _CurrentTaskState extends State<CurrentTask> {

  String buttonText = '抵達乘客上車地點';
  bool isPassengerOnBoard = false;
  String taskStatus = '接客中';
  bool isNextTaskVisible = false;
  String? userToken;
  bool isRequesting = false;

  Timer? _fetchTimer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // fetchNewTask();
    var userModel = context.read<UserModel>();
    userToken = userModel.token!;

    var taskModel = context.read<TaskModel>();

    _fetchTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      _fetchCaseState(userToken!, taskModel.cases.first.id!);
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

              // checkAvailableAndShow() async {
              //   bool isGoogleMaps =
              //       await MapLauncher.isMapAvailable(MapType.google) ?? false;
              //
              //   if (isGoogleMaps) {
              //     await MapLauncher.showDirections(
              //       mapType: MapType.google,
              //       directionsMode: DirectionsMode.driving,
              //       destinationTitle: taskModel.cases.first.onAddress!,
              //       destination: Coords(25.033582,121.501609) ,
              //     );
              //   }
              // }
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
                              Text('${taskModel.cases.first.carTeamName}')
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
                                    icon: const Icon(Icons.near_me_outlined,size: 16,),
                                    title: '導航',
                                    color: AppColor.primary,
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
                                    })
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
                            ],
                          )
                              :
                          Container(),
                          const SizedBox(height: 10,),
                          CustomElevatedButton(
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
                  // next task
                  (taskModel.cases.length>1)?
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
                                  text: '下個任務：',
                                  style: const TextStyle(color: Colors.black87, fontSize: 18,),
                                  children: <TextSpan>[
                                    TextSpan(text: taskStatus,style: const TextStyle(color: AppColor.red,fontSize: 22,fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            margin: const EdgeInsets.fromLTRB(0,10,0,0),
                            child: Row(
                              children: [
                                const Text('上車地：'),
                                CustomSmallElevatedButton(
                                    icon: const Icon(Icons.near_me_outlined,size: 16,),
                                    title: '導航',
                                    color: AppColor.primary,
                                    onPressed: (){
                                      // _launchMap(widget.theCase.onAddress!);
                                      MapsLauncher.launchQuery(taskModel.cases[1].onAddress!);
                                    })
                              ],
                            ),
                          ),
                          Container(
                            child: Text('${taskModel.cases[1].onAddress}'),
                          ),
                          Container(
                            margin: const EdgeInsets.fromLTRB(0,10,0,0),
                            child: Row(
                              children: [
                                const Text('乘客：'),
                                const SizedBox(width: 10),
                                CustomSmallElevatedButton(
                                    icon: const Icon(Icons.call_outlined,size: 16,),
                                    title: '電話',
                                    color: AppColor.primary,
                                    onPressed: (){
                                      Uri uri = Uri.parse("tel://${taskModel.cases[1].customerPhone}");
                                      launchUrl(uri);
                                    })
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.fromLTRB(0,0,0,10),
                            child: Row(
                              children: [
                                Text(taskModel.cases[1].customerName!),
                                const SizedBox(width: 10),
                                Text('${taskModel.cases[1].customerPhone}'),
                              ],
                            ),
                          ),
                          (taskModel.cases[1].memo!="")?Text('備註：${taskModel.cases[1].memo}'):Container(),
                        ],
                      )
                  )
                      :
                  Container()
                ],
              );
            }),
          ),
        )
    );
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
        taskModel.isOnTask = true;
        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => OnTask(theCase: taskModel.cases.first)));
        if(result == 'canceled'){
          Navigator.pop(context,'canceled');
        }
        setState(() {});
      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('可能網路不佳，請再試一次！')));
      }

    } catch (e) {
      print(e);
      return "error";
    }
    isRequesting = false;
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
        taskModel.resetTask();
        //回到首頁並帶參數
        Navigator.pop(context,'canceled');
      }

      setState(() {});

    } catch (e) {
      print(e);
    }
  }

  // Future _putCaseCanceled(String token, String memo, int caseId) async {
  //   String path = ServerApi.PATH_CASE_CANCEL;
  //
  //   try {
  //     final bodyParams = {
  //       'memo': memo,
  //     };
  //
  //     final queryParameters = {
  //       'case_id': caseId.toString(),
  //     };
  //
  //     final response = await http.put(
  //       ServerApi.standard(path: path, queryParameters: queryParameters),
  //       headers: <String, String>{
  //         'Content-Type': 'application/json; charset=UTF-8',
  //         'Authorization': 'Token $token',
  //       },
  //       body: jsonEncode(bodyParams)
  //     );
  //
  //     Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
  //     if(map['message']=='ok'){
  //       var taskModel = context.read<TaskModel>();
  //       taskModel.resetTask();
  //       if(taskModel.cases.isEmpty) {
  //         Navigator.popUntil(context, ModalRoute.withName('/main'));
  //       }else{
  //         setState(() {});
  //       }
  //     }else{
  //       ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('可能網路不佳，請再試一次！')));
  //     }
  //
  //   } catch (e) {
  //     print(e);
  //     return "error";
  //   }
  // }
  //
  // void _launchMap(String address) async {
  //   String query = Uri.encodeComponent(address);
  //   String googleUrl = "https://www.google.com/maps/search/?api=1&query=$query";
  //   Uri googleUri = Uri.parse(googleUrl);
  //
  //   if (await canLaunchUrl(googleUri)) {
  //     await launchUrl(googleUri);
  //   }
  // }
  //
  // //乘客上車了
  // Future _putCaseCatched(String token, Case theCase) async {
  //   String path = ServerApi.PATH_CASE_CATCHED;
  //
  //   try {
  //     // Map queryParameters = {
  //     //   'phone': user.phone,
  //     // };
  //
  //     final queryParameters = {
  //       'case_id': theCase.id.toString(),
  //     };
  //
  //     final response = await http.put(
  //       ServerApi.standard(path: path, queryParameters: queryParameters),
  //       headers: <String, String>{
  //         'Content-Type': 'application/json; charset=UTF-8',
  //         'Authorization': 'Token $token',
  //       },
  //       // body: jsonEncode(queryParameters)
  //     );
  //
  //     print(response.body);
  //
  //     Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
  //     if(map['message']=='ok'){
  //       var taskModel = context.read<TaskModel>();
  //       taskModel.isOnTask = true;
  //       Navigator.push(context, MaterialPageRoute(builder: (context) => OnTask(theCase: theCase)));
  //       setState(() {});
  //     }else{
  //       ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('可能網路不佳，請再試一次！')));
  //     }
  //
  //   } catch (e) {
  //     print(e);
  //     return "error";
  //   }
  // }

  // Future _getLatLngFromAddress(String address) async{
  //   String geocodingKey = "AIzaSyCrzmspoFyEFYlQyMqhEkt3x5kkY8U3C-Y";
  //   String path = '${ServerApi.PATH_GEOCODE}$address&key=$geocodingKey';
  //   print(path);
  //   try {
  //     final response = await http.get(Uri.parse(path));
  //     if (response.statusCode == 200) {
  //       Map<String, dynamic> data = json.decode(response.body);
  //       print(data['status']);
  //       print(data['results'][0]['formatted_address']);
  //       setState(() {});
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  // }

}




