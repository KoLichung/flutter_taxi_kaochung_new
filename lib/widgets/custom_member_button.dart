import 'package:flutter/material.dart';

import '../color.dart';

class CustomMemberPageButton extends StatelessWidget {
  final String title;
  final Function onPressed;

  CustomMemberPageButton({required this.title, required this.onPressed, });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: ListTile(
              title: Text(title),
              trailing: SizedBox(
                width: 30,
                child: IconButton(
                  onPressed: () {
                    onPressed();
                  },
                  icon: const Icon(Icons.arrow_forward_ios,color: Colors.black54,),
                ),
              ),
            )), //LINE小秘書
        const Divider(
          indent: 20,
          height: 1,
          thickness: 1,
          color: Colors.black54,
        ),
      ],
    );
  }
}

