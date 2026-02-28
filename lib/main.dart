import 'dart:io';
import 'dart:async'; // Timer এর জন্য এটি লাগবে
import 'package:flutter/material.dart';
import 'package:one_vaults/AddVaults.dart';
import 'package:one_vaults/AllVaults.dart';
import 'package:one_vaults/PinLockScreen.dart';
import 'package:one_vaults/SettingsPage.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(420, 620),
      minimumSize: Size(400, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      title: "One Vaults",
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: true,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(true);
    });
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  final SystemTray _systemTray = SystemTray();
  final AppWindow _appWindow = AppWindow();

  // নেভিগেশন কন্ট্রোল করার জন্য কি (Key)
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // অটো-লক টাইমার
  Timer? _autoLockTimer;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.addListener(this);
      initSystemTray();
    }
    _resetAutoLockTimer(); // অ্যাপ শুরুতেই টাইমার শুরু হবে
  }

  @override
  void dispose() {
    _autoLockTimer?.cancel();
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  // --- লকিং লজিক ---
  void _lockVault() {
    // ইউজারকে সরাসরি পিন স্ক্রিনে পাঠিয়ে দেওয়া এবং আগের সব রুট ক্লিয়ার করা
    _navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
    debugPrint("Vault Locked!");
  }

  // --- অটো-লক টাইমার লজিক (১০ মিনিট) ---
  void _resetAutoLockTimer() {
    _autoLockTimer?.cancel();
    _autoLockTimer = Timer(const Duration(minutes: 10), () {
      _lockVault();
    });
  }

  // ইউজার স্ক্রিনে টাচ বা ক্লিক করলে টাইমার রিসেট হবে
  void _handleUserInteraction() {
    _resetAutoLockTimer();
  }

  // পিসির (X) ক্লোজ বাটন হ্যান্ডেল করা
  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      _lockVault(); // ক্লোজ করলে অটো লক হবে
      await windowManager.hide(); // তারপর হাইড হবে
    }
  }

  Future<void> initSystemTray() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;

    String iconPath = Platform.isWindows
        ? 'assets/icon/tray_icon.ico'
        : 'assets/icon/tray_icon.png';

    try {
      await _systemTray.initSystemTray(
        title: "One Vaults",
        iconPath: iconPath,
      );

      final Menu menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(
          label: 'Show Vaults',
          onClicked: (menuItem) => windowManager.show(),
        ),
        MenuItemLabel(
          label: 'Lock Vaults',
          onClicked: (menuItem) => _lockVault(),
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: 'Exit',
          onClicked: (menuItem) => windowManager.destroy(),
        ),
      ]);

      await _systemTray.setContextMenu(menu);

      _systemTray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          Platform.isWindows ? windowManager.show() : _appWindow.show();
        } else if (eventName == kSystemTrayEventRightClick) {
          _systemTray.popUpContextMenu();
        }
      });
    } catch (e) {
      debugPrint("System Tray Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _handleUserInteraction(),
      child: MaterialApp(
        navigatorKey: _navigatorKey, // এটি অবশ্যই দিতে হবে
        title: "One Vaults",
        routes: {
          "/": (context) => PinLockScreen(),
          "/addVault": (context) => AddVaults(),
          "/allVault": (context) => AllVaultsPage(),
          "/settings": (context) => Settings(),
        },
        initialRoute: '/',
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}