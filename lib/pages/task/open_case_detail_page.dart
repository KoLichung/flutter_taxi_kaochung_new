import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_taxi_chinghsien/widgets/custom_small_elevated_button.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../color.dart';
import '../../config/serverApi.dart';
import '../../models/case.dart';
import '../../notifier_models/task_model.dart';
import '../../notifier_models/user_model.dart';
import '../../widgets/custom_elevated_button.dart';
import 'cancel_dialog.dart';
import 'current_task.dart';

class OpenCaseDetailPage extends StatefulWidget {

  final int caseId;

  const OpenCaseDetailPage({Key? key, required this.caseId}) : super(key: key);

  @override
  _OpenCaseDetailPageState createState() => _OpenCaseDetailPageState();
}

class _OpenCaseDetailPageState extends State<OpenCaseDetailPage> {

  bool isCaseConfirming = false;
  bool isAddressCopied = false;
  Case? theCase;

  @override
  void initState() {
    super.initState();
    // print(widget.caseId);
    _fetchCaseState(widget.caseId);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('案件詳細'),
            ),
            body: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 18,vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14,vertical: 14),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColor.primary, width: 1),
                    borderRadius: BorderRadius.circular(3)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      (theCase==null)?Text('讀取中...'):Text('${theCase!.carTeamName}'),
                      Row(
                        children: [
                          const Text('上車地：'),
                          (theCase==null)?Container():
                          CustomSmallElevatedButton(
                              icon: const Icon(Icons.copy,size: 16,),
                              title: '複製',
                              color: isAddressCopied? Colors.grey : AppColor.primary,
                              onPressed: ()async{
                                if(!isAddressCopied){
                                  isAddressCopied = true;
                                }
                                await Clipboard.setData(ClipboardData(text: theCase!.onAddress!));
                                ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('已複製上車地址')));
                                setState(() {});
                              }),
                        ],
                      ),
                      (theCase==null)?Container():Text('${theCase!.onAddress}'),
                      (theCase==null)?Container():Text('時間：${theCase!.timeMemo}'),
                      (theCase==null)?Container():Text('備註：${theCase!.memo}'),
                      const SizedBox(height: 10,),
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: 1,
                            child:
                            Container(
                              padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
                              child: CustomElevatedButton(
                                onPressed: (){
                                  if(isCaseConfirming){
                                    ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('訂單確認中！')));
                                  }else{
                                    //here need to be revised
                                    var userModel = context.read<UserModel>();
                                    _putCaseConfirm(userModel.token!, theCase!, 5);
                                  }
                                },
                                title: "5分鐘",
                                theHeight: 40,
                                isChangeToSmallSize: true,
                              ),
                            )
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                              child: CustomElevatedButton(
                                onPressed: (){
                                  if(isCaseConfirming){
                                    ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('訂單確認中！')));
                                  }else{
                                    //here need to be revised
                                    var userModel = context.read<UserModel>();
                                    _putCaseConfirm(userModel.token!, theCase!, 10);
                                  }
                                },
                                title: "10分鐘",
                                theHeight: 40,
                                isChangeToSmallSize: true,
                              ),
                            )
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                              child: CustomElevatedButton(
                                onPressed: (){
                                  if(isCaseConfirming){
                                    ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('訂單確認中！')));
                                  }else{
                                    //here need to be revised
                                    var userModel = context.read<UserModel>();
                                    _putCaseConfirm(userModel.token!, theCase!, 15);
                                  }
                                },
                                title: "15分鐘",
                                theHeight: 40,
                                isChangeToSmallSize: true,
                              ),
                            )
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                              flex: 1,
                              child:
                              Container(
                                padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
                                child: CustomElevatedButton(
                                  onPressed: (){
                                    if(isCaseConfirming){
                                      ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('訂單確認中！')));
                                    }else{
                                      //here need to be revised
                                      var userModel = context.read<UserModel>();
                                      _putCaseConfirm(userModel.token!, theCase!, 20);
                                    }
                                  },
                                  title: "20分鐘",
                                  theHeight: 40,
                                  isChangeToSmallSize: true,
                                ),
                              )
                          ),
                          Expanded(
                              flex: 1,
                              child: Container(
                                padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                                child: CustomElevatedButton(
                                  onPressed: (){
                                    if(isCaseConfirming){
                                      ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('訂單確認中！')));
                                    }else{
                                      //here need to be revised
                                      var userModel = context.read<UserModel>();
                                      _putCaseConfirm(userModel.token!, theCase!, 25);
                                    }
                                  },
                                  title: "25分鐘",
                                  theHeight: 40,
                                  isChangeToSmallSize: true,
                                ),
                              )
                          ),
                          Expanded(
                              flex: 1,
                              child: Container(
                                padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                                child: CustomElevatedButton(
                                  onPressed: (){
                                    if(isCaseConfirming){
                                      ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('訂單確認中！')));
                                    }else{
                                      //here need to be revised
                                      var userModel = context.read<UserModel>();
                                      _putCaseConfirm(userModel.token!, theCase!, 30);
                                    }
                                  },
                                  title: "30分鐘",
                                  theHeight: 40,
                                  isChangeToSmallSize: true,
                                ),
                              )
                          ),
                        ],
                      ),
                      CustomElevatedButton(
                        color: AppColor.red,
                        theHeight: 40,
                        onPressed: (){
                          Navigator.pop(context);
                        },
                        title: '不接，返回',
                        isChangeToSmallSize: true,
                      ),
                    ]),
              ),
            ),
      )
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  Future _fetchCaseState(int caseId) async {
    String path = ServerApi.PATH_GET_CASE_DETAIL;

    try {
      final queryParameters = {
        'case_id': caseId.toString(),
      };

      final response = await http.get(
        ServerApi.standard(path: path,queryParameters: queryParameters),
      );

      // print(response.body);

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      theCase = Case.fromJson(map);
      print('case state ${theCase?.caseState}');
      if(theCase?.caseState != 'open_case'){

        //回到上一頁並帶參數
        Navigator.pop(context, "refresh");
      }

      setState(() {});

    } catch (e) {
      print(e);
    }
  }

  Future _putCaseConfirm(String token, Case theCase, int expect_minutes) async {
    print("case confirm");
    isCaseConfirming = true;
    String path = ServerApi.PATH_CASE_CONFIREM;

    try {
      final queryParameters = {
        'case_id': theCase.id!.toString(),
        'expect_minutes': expect_minutes.toString(),
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
        var taskModel = context.read<TaskModel>();
        theCase.caseState='way_to_catch';
        taskModel.cases.clear();
        taskModel.cases.add(theCase);

        taskModel.isOpenCaseRefresh = true;

        theCase.expectSecond = (expect_minutes) * 60;
        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CurrentTask(isOpenCase: true)));
        isCaseConfirming = false;

        print(result);
        if(taskModel.isCanceled == true){
          _playCancelAsset();
          // Navigator.pop(context, "refresh");
          ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('訂單被取消了！')));
        }

        var userModel = context.read<UserModel>();
        if(taskModel.cases.isNotEmpty){
          _putCaseConfirm(userModel.token!, taskModel.cases.first, 0);
        }else{
          setState(() {});
        }

      }else{
        isCaseConfirming = false;
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('這個單可能已經被接走！')));
      }

      setState(() {});
    } catch (e) {
      print(e);
      isCaseConfirming = false;
      ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('這個單可能已經被接走！')));
      // return "error";
    }
  }

  void _printLongString(String text) {
    final RegExp pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((RegExpMatch match) => print(match.group(0)));
  }

  Future<AudioPlayer> _playCancelAsset() async {
    AudioCache cache = AudioCache();
    //At the next line, DO NOT pass the entire reference such as assets/yes.mp3. This will not work.
    //Just pass the file name only.
    return await cache.play("cancel_2.mp3");
  }

}




