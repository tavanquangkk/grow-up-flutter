import 'package:flutter/material.dart';

class MyWorkshopsScreen extends StatelessWidget {
  const MyWorkshopsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('自分の作成した勉強会')),
      body: const Center(child: Text('ここに自分の勉強会一覧を表示')),
    );
  }
}
