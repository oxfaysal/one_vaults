import 'dart:io';

import 'package:flutter/material.dart';
import 'package:one_vaults/AddVaults.dart';
import 'package:one_vaults/AllVaults.dart';
import 'package:window_manager/window_manager.dart';

import 'HomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ডেস্কটপের জন্য উইন্ডো কনফিগারেশন
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(420, 600),          // শুরুর সাইজ (Width, Height)
      minimumSize: Size(400, 600),   // সর্বনিম্ন সাইজ
      center: true,                  // স্ক্রিনের মাঝখানে দেখাবে
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      title: "One Vaults",           // উইন্ডোর টাইটেল
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "One Vaults",
      routes: {
        "/" : (context) => HomePage(),
        "/addVault" : (context) => AddVaults(),
        "/allVault" : (context) => AllVaultsPage(),
      },
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
    );
  }

}