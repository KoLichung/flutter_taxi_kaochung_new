import 'dart:convert';
import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_taxi_chinghsien/config/serverApi.dart';
import 'package:flutter_taxi_chinghsien/models/user_store_money.dart';
import 'package:flutter_taxi_chinghsien/widgets/custom_elevated_button.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../color.dart';
import '../../models/case.dart';
import '../../models/fee_rule.dart';
import '../../notifier_models/user_model.dart';
import 'recent_order_detail_dialog.dart';
import 'package:http/http.dart' as http;

class FeeRulePage extends StatefulWidget {
  const FeeRulePage({Key? key}) : super(key: key);

  @override
  _FeeRulePageState createState() => _FeeRulePageState();
}

class _FeeRulePageState extends State<FeeRulePage> {

  List<FeeRule> feeRules = [];
  int selectedRuleId = 1;

  bool isUpdating = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchFeeRules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          centerTitle: true,
          title:
          Container(
            margin: const EdgeInsets.fromLTRB(0, 0, 45, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('費率變更'),
              ],
            ),
          ),
          actions: [
            TextButton(
                child: const Text('確認儲存',style: TextStyle(color: Colors.red),) ,
                onPressed: (){
                  isUpdating = true;

                  var userModel = context.read<UserModel>();
                  _putUpdateFeeRule(userModel.token!, selectedRuleId);
                  setState(() {});
                })
          ],
        ),
        body:
        (isUpdating)?
        const Center(child: CircularProgressIndicator())
        :
        feeRules.length == 0?
            Center(
              child: Text('讀取中...'),
            )
        :
        ListView.builder(
          itemCount: feeRules.length,
          itemBuilder: (context, index) {
            ListTile newListTile = ListTile(
              contentPadding: EdgeInsets.only(left: 15.0, right: 15.0,top: 5, bottom: 5),
              leading: Radio(
                // activeColor: Color(0xff535353),
                value: feeRules[index].id!,
                onChanged: (int? value) {
                  setState(() {
                    selectedRuleId = value!;
                  });
                },
                groupValue: selectedRuleId,
              ),
              title: Column(
                children: [
                  Container(
                    width: double.infinity,
                    child: Text(feeRules[index].title!,textAlign: TextAlign.left,),
                  ),
                  Container(
                    width: double.infinity,
                    child: Text('起步\$${feeRules[index].startFee!},每200m\$${feeRules[index].twoHundredMeterFee!},每15secs\$${feeRules[index].fifteenSecondFee!}', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            );
            return newListTile;
          },
        ),
    );
  }

  Future _fetchFeeRules() async {
    print('fetching');
    var userModel = context.read<UserModel>();
    if(userModel.token != null){
      String path = ServerApi.PATH_GET_FEE_RULES;
      try {
        final response = await http.get(
          ServerApi.standard(path: path),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'token ${userModel.token}'
          },
        );

        _printLongString(response.body);

        List body = json.decode(utf8.decode(response.body.runes.toList()));
        for(var i in body){
          // print(i);
          if(i['isUserRule']==true){
            print(i['id']);
            selectedRuleId = i['id'];
          }
        }
        feeRules = body.map((value) => FeeRule.fromJson(value)).toList();
        setState(() {});

        // }
      } catch (e) {
        print(e);
      }
    }else{
      Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
    }
  }

  Future _putUpdateFeeRule (String token, int feeRuleId)async{
    String path = ServerApi.PATH_UPDATE_FEE_RULE;
    try{
      final bodyParams ={
        'fee_rule_id':feeRuleId,
      };

      final response = await http.put(ServerApi.standard(path:path),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'token $token'
        },
        body: jsonEncode(bodyParams),
      );
      print(response.body);
      if(response.statusCode == 200){
        print('success update feeRule');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("成功更新！"),
            )
        );
        Navigator.pop(context);
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("更新失敗！"),
            )
        );
        isUpdating = false;
        setState(() {});
      }

    } catch (e){
      print(e);
      isUpdating = false;
      setState(() {});
    }

  }

  void _printLongString(String text) {
    final RegExp pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((RegExpMatch match) =>   print(match.group(0)));
  }

}