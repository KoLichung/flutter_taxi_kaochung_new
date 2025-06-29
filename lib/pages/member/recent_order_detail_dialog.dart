import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../color.dart';
import '../../models/case.dart';


class RecentOrderDetailDialog extends StatefulWidget {

  Case theCase;
  RecentOrderDetailDialog({Key? key, required this.theCase}) : super(key: key);

  @override
  _RecentOrderDetailDialogState createState() => new _RecentOrderDetailDialogState();
}

class _RecentOrderDetailDialogState extends State<RecentOrderDetailDialog> {

  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.all(0),
      title: Container(
        width: 300,
        padding: const EdgeInsets.all(15),
        color: AppColor.primary,
        child: const Text(
          '歷史訂單',
          style: TextStyle(color: Colors.white),
        ),
      ),
      contentPadding: const EdgeInsets.all(0),
      content: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 36,vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.theCase.createTime} '),
            const SizedBox(height: 10,),
            Text('派單車隊：${widget.theCase.carTeamName} ',),
            const SizedBox(height: 10,),
            Text('派單人：${widget.theCase.dispatcherNickName} ',),
            const SizedBox(height: 10,),
            Text('上車：${widget.theCase.onAddress} ',),
            const SizedBox(height: 10,),
            Text('下車：${widget.theCase.offAddress} '),
            const SizedBox(height: 10,),
            Text('車資 \$ ${widget.theCase.caseMoney} '),
            const SizedBox(height: 10,),
            Text('備註：${widget.theCase.memo ?? '無'} '),
          ],
        ),
      ),
      backgroundColor: AppColor.primary,
      actions: <Widget>[
        OutlinedButton(
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('確定', style: TextStyle(color: Colors.white)))
      ],
    );
  }
}



