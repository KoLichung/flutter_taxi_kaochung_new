import 'package:flutter/material.dart';
import '../color.dart';

class CustomSmallOutlinedText extends StatelessWidget {

  final String title;
  final Color color;

  const CustomSmallOutlinedText({Key? key, required this.title, required this.color }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin:const EdgeInsets.fromLTRB(0,0,0,0),
        padding:const EdgeInsets.symmetric(vertical: 2,horizontal: 8),
        decoration:BoxDecoration(
          border: Border.all(color: color, width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(title ,style: TextStyle(color: color),),
      );
  }

}