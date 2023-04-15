import 'package:flutter/material.dart';
import 'package:flutter_taxi_chinghsien/color.dart';

class CurrentTaskReportDialog extends StatefulWidget {


  const CurrentTaskReportDialog({Key? key});

  @override
  _CurrentTaskReportDialogState createState() => new _CurrentTaskReportDialogState();
}

class _CurrentTaskReportDialogState extends State<CurrentTaskReportDialog> {

  TextEditingController memoController = TextEditingController();

  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      titlePadding: const EdgeInsets.all(0),
      title: Container(
        width: 360,
        padding: const EdgeInsets.all(10),
        color: AppColor.primary,
        child: const Text(
          '問題回報',
          style: TextStyle(color: Colors.white),
        ),
      ),
      contentPadding: const EdgeInsets.all(0),
      content: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
        Container(
          decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),),
        child: TextField(
          maxLines: 10,
          controller: memoController,
          decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(10),
              hintText: '請將案件問題寫於此處~',
              focusedBorder: InputBorder.none,
              border: InputBorder.none
          ),
        ),),
          ],
        ),
      ),
      backgroundColor: AppColor.primary,
      actions: <Widget>[
        OutlinedButton(
          child:const  Text('確認回報', style: TextStyle(color: Colors.white),),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
          onPressed: () {
            String text = memoController.text;
            Navigator.pop(context,text);
          }
        ),
      ],
    );
  }



}

