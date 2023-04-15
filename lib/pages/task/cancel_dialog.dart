import 'package:flutter/material.dart';
import 'package:flutter_taxi_chinghsien/color.dart';


class CancelDialog extends StatefulWidget {

  const CancelDialog({Key? key});

  @override
  _CancelDialogState createState() => _CancelDialogState();
}

class _CancelDialogState extends State<CancelDialog> {

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.all(0),
      title: Container(
        width: 360,
        padding: const EdgeInsets.all(10),
        color: AppColor.primary,
        child: const Text('任務取消', style: TextStyle(color: Colors.white),),
      ),
      contentPadding: const EdgeInsets.all(0),
      content: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('乘客已取消，請勿前往。'),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: AppColor.primary,
      actions: <Widget>[
        OutlinedButton(
            child:const  Text('確定', style: TextStyle(color: Colors.white),),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
            onPressed: () {
              Navigator.pop(context);
            }
        ),
      ],
    );
  }

}

