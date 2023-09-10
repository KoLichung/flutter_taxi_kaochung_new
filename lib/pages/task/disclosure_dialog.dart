import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../color.dart';

class DisclosureDialog extends StatefulWidget {

  const DisclosureDialog({Key? key}) : super(key: key);

  @override
  _DisclosureDialogState createState() => _DisclosureDialogState();
}

class _DisclosureDialogState extends State<DisclosureDialog> {


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.all(0),
      title: Container(
        width: 300,
        padding: const EdgeInsets.all(10),
        color: AppColor.primary,
        child: const Text(
          '使用您的位置位置',
          style: TextStyle(color: Colors.white),
        ),
      ),
      contentPadding: const EdgeInsets.all(0),
      content: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Text(
          '24H 收集位置資訊，以知道您的位置，並傳送附近案件給您，為保持功能正常，即使未使用 App 時，我們也會收集資料。\n\n這些資料會上傳 24H 的網路主機，分析後傳送附近案件給您，請允許使用位置。'
        ),
      ),
      backgroundColor: AppColor.primary,
      actions: <Widget>[
        OutlinedButton(
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
            onPressed: () {
              setState(() {
                Navigator.pop(context);
              });
            },
            child: const Text('確認', style: TextStyle(color: Colors.white)))
      ],
    );
  }
}