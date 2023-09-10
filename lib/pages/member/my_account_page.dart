import 'package:flutter/material.dart';
import 'package:flutter_taxi_chinghsien/config/serverApi.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../color.dart';
import '../../models/user.dart';
import '../../notifier_models/user_model.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_member_button.dart';
import '../register.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({Key? key}) : super(key: key);

  @override
  _MyAccountPageState createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {

  _deleteUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
    await prefs.remove('user');
  }

  @override
  Widget build(BuildContext context) {
    var userModel = context.read<UserModel>();
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
        resizeToAvoidBottomInset: false,
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
          // actions: [
          //   Padding(
          //     padding: const EdgeInsets.fromLTRB(0,10,10,10),
          //     child: IconButton(
          //         onPressed: (){},
          //         icon: const Icon(Icons.notifications_outlined)),)],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20,20,15,0),
                child:
                Row(
                  children: [
                    const Text('姓名：', style: TextStyle(fontSize: 18),),
                    Text(userModel.user!.name!, style: const TextStyle(fontSize: 18),),
                  ],),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20,0,15,10),
                child: Row(
                    children: [
                      const Text('狀態：', style: TextStyle(fontSize: 18),),
                      (userModel.user!.isPassed!)
                          ? const Text('登入中', style: TextStyle(fontSize: 18))
                          : const Text('登入中(尚未通過審核)', style: TextStyle(fontSize: 18)),
                    ]
                ),
              ),
              const Divider(
                color: Colors.black54,
                thickness: 1,
              ),
              CustomMemberPageButton(
                title: '基本資料',
                onPressed: (){
                  Navigator.push(
                      context,
                      // MaterialPageRoute(builder: (context) => const Register(isEdit: true, lineId: ""))
                      MaterialPageRoute(builder: (context) => const Register(isEdit: true,))
                  );
                },
              ),
              CustomMemberPageButton(
                title: '儲值紀錄',
                onPressed: (){
                  Navigator.pushNamed(context, '/money_record');
                },
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(30,20,30,0),
                child: CustomElevatedButton(
                  title: '登出',
                  theHeight: 46,
                  onPressed: () async {
                    // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MyHomePage()), (Route<dynamic> route) => false, );
                    print('here');
                    // _lineLogOut();
                    _putUpdateOnlineState(userModel.token!, false);
                    userModel.token = null;
                    userModel.removeUser(context);
                    userModel.resetPositionParams();
                    // if(userModel.positionStreamSubscription!=null){
                    //   print("not null positionStreamSubscription");
                    //   userModel.positionStreamSubscription!.pause();
                    //   userModel.positionStreamSubscription!.cancel();
                    //   userModel.positionStreamSubscription = null;
                    // }
                    _deleteUserToken();
                    Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
                  },
                ),
              ),
              Container(
                  margin: const EdgeInsets.fromLTRB(30,20,30,0),
                  child: ElevatedButton(
                      onPressed: () async {
                        final confirmBack = await _showDeleteDialog(context);
                        if(confirmBack){
                          print('here');
                          var userModel = context.read<UserModel>();
                          print(userModel.user!.id);
                          _deleteUserData(userModel.token!, userModel.user!.id!);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.red,
                          elevation: 0
                      ),
                      child: const SizedBox(
                        height: 46,
                        child: Align(
                          child: Text('刪除帳號',style: TextStyle(fontSize: 20),),
                          alignment: Alignment.center,
                        ),
                      )
                  )
              ),
              const SizedBox(height: 20,),
            ],
          ),
        ))
    );
  }

  // Future<void> _lineLogOut() async {
  //   try {
  //     await LineSDK.instance.logout();
  //   } on PlatformException catch (e) {
  //     print(e.message);
  //   }
  // }

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

      print(response.body);
      Map<String, dynamic> map = json.decode(utf8.decode(response.body.runes.toList()));
      if(map['message']=='ok'){
        print("success update online state!");
      }
    } catch (e) {
      print(e);
      return "error";
    }
  }

  Future _showDeleteDialog(BuildContext context) {
    AlertDialog dialog = AlertDialog(
      title: const Text("提醒您～！"),
      content: const Text('用戶刪除後，無法取回用戶資料！'),
      actions: [
        ElevatedButton(
            child: const Text("取消"),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                elevation: 0
            ),
            onPressed: () {
              Navigator.pop(context, false);
            }
        ),
        ElevatedButton(
            child: Text("確認刪除"),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.red,
                elevation: 0
            ),
            onPressed: () {
              Navigator.pop(context, true);
            }
        ),
      ],
    );

    // Show the dialog
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return dialog;
        }
    );
  }

  Future<User?> _deleteUserData(String token,int userId) async {
    String path = ServerApi.PATH_DELETE_USER+userId.toString()+'/';

    try {
      final response = await http.delete(
        ServerApi.standard(path: path),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
      );

      print(response.body);
      _printLongString(response.body);

      if(response.body.contains('delete user')){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("成功刪除使用者!"),));
        var userModel = context.read<UserModel>();
        userModel.removeUser(context);
        userModel.resetPositionParams();
        // if(userModel.positionStreamSubscription!=null){
        //   print("not null positionStreamSubscription");
        //   userModel.positionStreamSubscription!.pause();
        //   userModel.positionStreamSubscription!.cancel();
        //   userModel.positionStreamSubscription = null;
        // }
        bg.BackgroundGeolocation.stop();

        Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
      }

    } catch (e) {
      print(e);
    }
    return null;
  }

  void _printLongString(String text) {
    final RegExp pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((RegExpMatch match) => print(match.group(0)));
  }

}

