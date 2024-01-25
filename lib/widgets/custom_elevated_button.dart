import 'package:flutter/material.dart';
import '../color.dart';

class CustomElevatedButton extends StatelessWidget {

  final Function onPressed;
  final String title;
  Color? color;
  double theHeight = 46;
  bool? isChangeToSmallSize;

  CustomElevatedButton({Key? key, required this.onPressed,required this.title,required this.theHeight, this.color, this.isChangeToSmallSize}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
          onPressed: () {
            onPressed();
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: (color!=null)?color:AppColor.primary,
              elevation: 0
          ),
          child: SizedBox(
            height: theHeight,
            child: Align(
              child:
              (isChangeToSmallSize==null)?
              Text(title,style: const TextStyle(fontSize: 20),textAlign: TextAlign.center,)
              :
              Text(title,style: const TextStyle(fontSize: 15),textAlign: TextAlign.center,),
              alignment: Alignment.center,
            ),
          )
      );
  }

}