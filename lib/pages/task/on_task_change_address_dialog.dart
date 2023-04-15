import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_taxi_chinghsien/color.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../config/serverApi.dart';
import '../../notifier_models/task_model.dart';

class OnTaskChangeAddressDialog extends StatefulWidget {


  const OnTaskChangeAddressDialog({Key? key});

  @override
  _OnTaskChangeAddressDialogState createState() => new _OnTaskChangeAddressDialogState();
}

class _OnTaskChangeAddressDialogState extends State<OnTaskChangeAddressDialog> {

  TextEditingController addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      titlePadding: const EdgeInsets.all(0),
      title: Container(
        width: 360,
        padding: const EdgeInsets.all(10),
        color: AppColor.primary,
        child: const Text(
          '修改地址',
          style: TextStyle(color: Colors.white),
        ),
      ),
      contentPadding: const EdgeInsets.all(0),
      content: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 30),
        child: TextField(
          controller: addressController,
          maxLines: 1,
          decoration:  const InputDecoration(
              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              hintText: "輸入修改的地址",
          ),
        ),
      ),
      backgroundColor: AppColor.primary,
      actions: <Widget>[
        OutlinedButton(
            child:const  Text('確定', style: TextStyle(color: Colors.white),),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
            onPressed: () {
              String address = addressController.text;
              print(address);
              if(address!=''){
                _getLatLngFromAddress(address);
              }else{
                ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('地址不可空白！')));
              }
            }
        ),
      ],
    );
  }

  Future _getLatLngFromAddress(String address) async{
    String geocodingKey = "AIzaSyCrzmspoFyEFYlQyMqhEkt3x5kkY8U3C-Y";
    String path = '${ServerApi.PATH_GEOCODE}$address&key=$geocodingKey';
    print(path);
    try {
      final response = await http.get(Uri.parse(path));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        print(data['status']);
        print(data['results'][0]['geometry']['location']);

        if(data['results'][0]['geometry']['location']!=null){
          var taskModel = context.read<TaskModel>();
          taskModel.cases.first.offLat = data['results'][0]['geometry']['location']['lat'].toString();
          taskModel.cases.first.offLng = data['results'][0]['geometry']['location']['lng'].toString();
          Navigator.pop(context,address);
        }else{
          ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('Google無法辨識此地址！')));
        }
      }else{
        ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('Google無法辨識此地址！')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)..removeCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('Google無法辨識此地址！')));
      print(e);
    }
  }

}

