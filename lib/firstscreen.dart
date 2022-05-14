import 'package:flutter/material.dart';
import 'package:testright_task/camerascreen.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Camera App"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (contex) => CameraScreen()));
          },
          child: Text("Open Camera"),
        ),
      ),
    );
  }
}
