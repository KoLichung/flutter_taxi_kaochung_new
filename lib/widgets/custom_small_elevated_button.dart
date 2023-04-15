import 'package:flutter/material.dart';

class CustomSmallElevatedButton extends StatelessWidget {

  final Icon icon;
  final String title;
  final Color color;
  final Function onPressed;

  const CustomSmallElevatedButton({Key? key, required this.icon, required this.title, required this.color, required this.onPressed,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return
      ElevatedButton(
          onPressed: () {
            onPressed();
          },
          style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 10,vertical: 1),
              minimumSize: const Size(0, 0),
              primary: color,
              elevation: 0
          ),
          child: Row(
            children: [
              icon,
              Text(title)
            ],
          )
      );
  }

}