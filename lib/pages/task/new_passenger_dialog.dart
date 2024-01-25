import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_taxi_chinghsien/config/serverApi.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../color.dart';
import '../../models/case.dart';
import '../../notifier_models/task_model.dart';
import '../../notifier_models/user_model.dart';
import '../../widgets/custom_small_oulined_text.dart';
import 'package:http/http.dart' as http;

import 'current_task.dart';

class NewPassengerDialog extends StatefulWidget {

  @override
  _NewPassengerDialogState createState() => new _NewPassengerDialogState();
}

class _NewPassengerDialogState extends State<NewPassengerDialog> {
  bool? isTakingNewPassenger;
  Future? _future;
  Case? theCase;
  Position? currentPosition;

  @override
  void initState(){
    super.initState();
    // _future = Future.delayed(const Duration(seconds: 5), () {
    //   Navigator.of(context).pop(true);
    // });

    var userModel = context.read<UserModel>();
    currentPosition = userModel.currentPosition;
    try{
      _fetchCases(userModel.token!);
    }catch(e){
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.only(top: 200),
      titlePadding: const EdgeInsets.all(0),
      title: Container(
        width: 300,
        padding: const EdgeInsets.all(15),
        color: AppColor.primary,
        child: const Text(
          '新任務：是否先承接起來？',
          style: TextStyle(color: Colors.white),
        ),
      ),
      contentPadding: const EdgeInsets.all(0),
      content: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 36,vertical: 30),
        child:
        (theCase != null )
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const CustomSmallOutlinedText(color: Colors.black87,title: '客戶',),
                      const SizedBox(width: 20,),
                      Text('距離 ${getDistance(theCase!, currentPosition!)}'),
                    ],
                  ),
                  const SizedBox(height: 10,),
                  Expanded(
                    child: Row(
                      children: [
                        const Text('預計行車時間：'),
                        Text('預估時間固定+ 120 秒'),
                      ],),
                  ),
                  const SizedBox(height: 10,),
                  Expanded(
                    child: Row(
                      children: [
                        const Text('上車位置：'),
                        Text(theCase!.onAddress!),
                      ],),
                  ),
                ],
              )
            : const Text('讀取中'),
      ),
      backgroundColor: AppColor.primary,
      actions: <Widget>[
        OutlinedButton(
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
            onPressed: () {
              if(_future!=null){
                print('cancel the future timer');
                _future!.timeout(const Duration(seconds: 0),onTimeout: () => 'cancel the future');
              }
              Navigator.of(context).pop();
            },
            child:const  Text('不接', style: TextStyle(color: Colors.white),
            )),
        OutlinedButton(
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
            onPressed: () {
              setState(() async {
                isTakingNewPassenger = true;

                if(_future!=null){
                  print('cancel the future timer');
                  _future!.timeout(const Duration(seconds: 0),onTimeout: () => 'cancel the future');
                }

                if(theCase!=null){
                  var taskModel = context.read<TaskModel>();
                  print(taskModel.cases);

                  var userModel = context.read<UserModel>();
                  final result = await _putCaseConfirm(userModel.token!, theCase!);
                  if (result != "error"){
                    if(taskModel.cases.isEmpty) {
                      print("case empty");
                      taskModel.addCase(theCase!);
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => CurrentTask(theCase: theCase!, isOpenCase: false)));
                    }else{
                      taskModel.addCase(theCase!);
                      Navigator.pop(context);
                    }
                  }
                }
              });
              print('in dialog $isTakingNewPassenger');
            },
            child: const Text('接', style: TextStyle(color: Colors.white)))
      ],
    );
  }

  Future _fetchCases(String token) async {
    String path = ServerApi.PATH_GET_CASES;
    try {
      final response = await http.get(
        ServerApi.standard(path: path),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'token $token'
        },
      );

      List body = json.decode(utf8.decode(response.body.runes.toList()));
      List<Case> cases = body.map((value) => Case.fromJson(value)).toList();
      if(cases.isNotEmpty){
        theCase = cases.first;
        setState(() {});
      }else{
        Navigator.pop(context);
      }

    } catch (e) {
      print(e);
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

      // print(response.body);
      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      if(map['message']=='ok'){
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('成功接單！')));
        return "ok";
      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('這個單可能已經被接走！請稍後再試！')));
        return "error";
      }
      setState(() {});
    } catch (e) {
      print(e);
      return "error";
    }
  }

  String getDistance(Case theCase, Position currentPosition){
    double distance = Geolocator.distanceBetween(currentPosition.latitude, currentPosition.longitude, double.parse(theCase.onLat!), double.parse(theCase.onLng!));
    if(distance > 1000){
      distance = distance / 1000;
      return distance.toStringAsFixed(2) + " 公里";
    }else{
      return distance.toStringAsFixed(0) + " 公尺";
    }
  }
}



