import 'package:flutter/material.dart';
import '../color.dart';

class CustomElevatedButton extends StatelessWidget {

  final Function onPressed;
  final String title;
  Color? color;

  CustomElevatedButton({Key? key, required this.onPressed,required this.title, this.color}) : super(key: key);

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
            height: 46,
            child: Align(
              child: Text(title,style: const TextStyle(fontSize: 20),),
              alignment: Alignment.center,
            ),
          )
      );
  }

}