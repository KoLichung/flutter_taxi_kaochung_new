import 'dart:async';
import 'dart:convert';

import 'package:flutter_taxi_chinghsien/main.dart';
import 'package:flutter_taxi_chinghsien/notifier_models/task_model.dart';
import 'package:flutter_taxi_chinghsien/pages/task/open_case_detail_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:provider/provider.dart';

import '../../config/serverApi.dart';
import '../../models/case.dart';
import '../../notifier_models/user_model.dart';
import '../../widgets/custom_elevated_button.dart';

class OpenCasePage extends StatefulWidget {

  const OpenCasePage({Key? key}) : super(key: key);

  @override
  _OpenCasePageState createState() => _OpenCasePageState();
}

class _OpenCasePageState extends State<OpenCasePage> {

  List<Case> openCases = [];
  final GlobalKey<LiquidPullToRefreshState> _refreshIndicatorKey = GlobalKey<LiquidPullToRefreshState>();

  @override
  void initState() {
    super.initState();
    var userModel = context.read<UserModel>();
    _fetchOpenCases(userModel.token!);
  }


  @override
  Widget build(BuildContext context) {
    return
      WillPopScope(
        onWillPop: () async => false,
        child:Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('未結案區'),
        ),
        body: LiquidPullToRefresh(
          springAnimationDurationInMilliseconds: 100,
          key: _refreshIndicatorKey,
          showChildOpacityTransition: false,// key if you want to add
          onRefresh: _handleRefresh,	// refresh callback
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: openCases.length + 1,
            itemBuilder: (context, index) {
              if(index == 0){
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 3,horizontal: 0),
                  child:Column(
                    children: const [
                      Center(
                          child: Text('下拉選單可以更新內容...')
                      ),
                      Divider(
                        color: Color(0xffC0C0C0),
                      ),
                    ],
                  ),
                );
              }

              return GestureDetector(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 5,horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${openCases[index-1].carTeamName}\n派單時間：${getTimeString(openCases[index-1].createTime!)}\n上車地：${openCases[index-1].onAddress}\n時間：${openCases[index-1].timeMemo}\n備註：${openCases[index-1].memo}'),
                          CustomElevatedButton(
                            theHeight: 40,
                            onPressed: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) =>  OpenCaseDetailPage(caseId: openCases[index-1].id!,)),
                              );
                              // if (result == 'refresh'){
                              //   _fetchOpenCases();
                              // }
                              var taskModel = context.read<TaskModel>();
                              if (result == 'refresh' || taskModel.isOpenCaseRefresh){
                                taskModel.isOpenCaseRefresh = false;

                                var userModel = context.read<UserModel>();
                                _fetchOpenCases(userModel.token!);
                              }

                            },
                            title: '訂單詳情',
                            isChangeToSmallSize: true,
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: Color(0xffC0C0C0),
                    ),
                  ],
                ),
                onTap: ()async{
                  print("good");
                } ,
              );
            },
          ),		// scroll view
        ),
      ),
      );
  }

  Future<void> _handleRefresh() async {
    final Completer<void> completer = Completer<void>();

    String path = ServerApi.PATH_OPEN_CASES;
    try {
      var userModel = context.read<UserModel>();
      final response = await http.get(
          ServerApi.standard(path: path),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Token ${userModel.token!}',
          },
      );

      // print(response.body);

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      List body = map["cases"];

      userModel.user!.leftMoney = map["left_money"];
      print('leftmoney ${userModel.user!.leftMoney}');

      if(map["left_money"]<= -100){
        openCases = [];
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('您的儲值金額小於-100元！無法閱讀案件')));
      }else {
        openCases = body.map((value) => Case.fromJson(value)).toList();
      }

      completer.complete();
      setState(() {});

    } catch (e) {
      print(e);
    }

    return completer.future.then<void>((_) {
      // ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('已更新！')));
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  String getTimeString(String timeString){
    DateTime dateTime = DateTime.parse(timeString);
    dateTime = dateTime.add(Duration(hours: 8));
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  Future _fetchOpenCases(String token) async {
    String path = ServerApi.PATH_OPEN_CASES;

    try {
      final response = await http.get(
        ServerApi.standard(path: path),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
      );

      // print(response.body);

      // List<dynamic> parsedListJson = json.decode(utf8.decode(response.body.runes.toList()));
      // openCases = List<Case>.from(parsedListJson.map((i) => Case.fromJson(i)));

      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      List body = map["cases"];

      var userModel = context.read<UserModel>();
      userModel.user!.leftMoney = map["left_money"];

      if(map["left_money"]<= -100){
        openCases = [];
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('您的儲值金額小於-100元！無法閱讀案件')));
      }else {
        openCases = body.map((value) => Case.fromJson(value)).toList();
      }
      setState(() {});


    } catch (e) {
      print(e);
    }
  }

}




