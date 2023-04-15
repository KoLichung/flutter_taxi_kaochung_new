import 'package:flutter/material.dart';
import 'package:flutter_taxi_chinghsien/color.dart';


class OnTaskPassengerOffDialog extends StatefulWidget {
  final int task_price;
  final int before_left_money;
  final int dispatch_fee;
  final int after_left_money;

  const OnTaskPassengerOffDialog({Key? key, required this.task_price,required this.before_left_money, required this.dispatch_fee, required this.after_left_money});

  @override
  _OnTaskPassengerOffDialogState createState() => new _OnTaskPassengerOffDialogState();
}

class _OnTaskPassengerOffDialogState extends State<OnTaskPassengerOffDialog> {

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.all(0),
      title: Container(
        width: 360,
        padding: const EdgeInsets.all(10),
        color: AppColor.primary,
        child: const Text('儲值金餘額統計', style: TextStyle(color: Colors.white),),
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
              children: [
                const Text('本趟結算車資：'),
                Text('${widget.task_price}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('扣款前儲值金額：'),
                Text('${widget.before_left_money}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('扣除金額：'),
                Text('${widget.dispatch_fee}'),
              ],
            ),
            const Divider(thickness: 1,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('扣款後餘額：'),
                Text('${widget.after_left_money}'),
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
              Navigator.popUntil(context, ModalRoute.withName('/main'));
            }
        ),
      ],
    );
  }

}

