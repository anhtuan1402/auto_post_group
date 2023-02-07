import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'user_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Facebook Auth Tutorial'),
        ),
        body: Center(
          child: SizedBox(
            height: 40,
            child: SignInButton(
              Buttons.FacebookNew,
              shape: ShapeBorder.lerp(
                  const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15.0))),
                  const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15.0))),
                  0.0),
              mini: false,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: ((context) => const UserScreen())));
              },
            ),
          ),
        ));
  }
}
