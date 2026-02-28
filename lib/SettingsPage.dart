import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'conts/Color.dart';
import 'conts/TextStyle.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLockEnabled = false;
  bool _obscureText = true;

  // Stealth Mode State
  bool _isStealthMode = false;
  String _selectedFakeName = "Calculator";
  final List<String> _fakeNames = ["Calculator", "Notepad", "Task Manager", "Excel", "System Info"];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // পিন, স্টিলথ মোড এবং ফেক নাম লোড করা
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String? pin = prefs.getString('user_pin');
    bool stealth = prefs.getBool('stealth_mode') ?? false;
    String savedName = prefs.getString('fake_app_name') ?? "Calculator";

    setState(() {
      _isStealthMode = stealth;
      _selectedFakeName = savedName;
      if (pin != null && pin.isNotEmpty) {
        _isLockEnabled = true;
        _pinController.text = pin;
      }
    });
  }

  // স্টিলথ মোড এবং নাম পরিবর্তন হ্যান্ডেল করা
  Future<void> _updateStealthSettings({bool? enabled, String? newName}) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      if (enabled != null) _isStealthMode = enabled;
      if (newName != null) _selectedFakeName = newName;
    });

    await prefs.setBool('stealth_mode', _isStealthMode);
    await prefs.setString('fake_app_name', _selectedFakeName);

    // ডেস্কটপ টাইটেল আপডেট
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      if (_isStealthMode) {
        await windowManager.setTitle(_selectedFakeName);
      } else {
        await windowManager.setTitle("One Vaults"); // আপনার অরিজিনাল অ্যাপ নাম
      }
    }

    if (enabled != null) {
      _showSnack(
          _isStealthMode ? "Stealth Mode চালু হয়েছে ($_selectedFakeName)" : "Stealth Mode বন্ধ হয়েছে",
          _isStealthMode ? Colors.blueGrey : Colors.orange,
          _isStealthMode ? Icons.visibility_off : Icons.visibility
      );
    }
  }

  Future<void> _handleSave() async {
    final prefs = await SharedPreferences.getInstance();
    String newPin = _pinController.text.trim();

    if (newPin.isEmpty) {
      await prefs.remove('user_pin');
      setState(() => _isLockEnabled = false);
      _showSnack("পিন লক বন্ধ করা হয়েছে", Colors.orange, Icons.lock_open);
    } else if (newPin.length >= 4 && newPin.length <= 6) {
      await prefs.setString('user_pin', newPin);
      setState(() => _isLockEnabled = true);
      _showSnack("পিন সফলভাবে সেভ হয়েছে", Colors.green, Icons.check_circle);
    } else {
      _showSnack("পিন অবশ্যই ৪-৬ ডিজিটের হতে হবে", Colors.red, Icons.error_outline);
    }
  }

  void _showSnack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(msg),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: APP_COLOR.mainBG,
      appBar: AppBar(
        title: Text("Settings", style: TEXT_STYLE.textNavyBlack20w500),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 40, width: 40,
              decoration: BoxDecoration(color: APP_COLOR.white, borderRadius: BorderRadius.circular(50)),
              child: const Icon(Icons.arrow_back, size: 20),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSecurityCard(),
            const SizedBox(height: 20),
            // ৩. স্টিলথ মোড কার্ড (ডেস্কটপ চেক সহ)
            if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux))
              _buildStealthCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isLockEnabled ? APP_COLOR.primary2Color.withOpacity(0.05) : Colors.transparent,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
            ),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: APP_COLOR.primary2Color, child: const Icon(Icons.shield, color: Colors.white, size: 20)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("App Lock Security", style: TEXT_STYLE.textNavyBlack16w700),
                      Text(_isLockEnabled ? "Your app is now secure" : "Lock is not set", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Switch(
                  value: _isLockEnabled,
                  activeColor: APP_COLOR.primary2Color,
                  onChanged: (val) {
                    if (!val) {
                      _pinController.clear();
                      _handleSave();
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Set Security PIN (4-6 Digits)", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 12),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: _obscureText,
                  style: const TextStyle(fontSize: 18, letterSpacing: 2),
                  decoration: InputDecoration(
                    hintText: "Enter your PIN",
                    hintStyle: const TextStyle(letterSpacing: 0, fontSize: 14),
                    filled: true,
                    fillColor: APP_COLOR.mainBG.withOpacity(0.4),
                    counterText: "",
                    prefixIcon: Icon(Icons.lock_outline, color: APP_COLOR.primary2Color),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: APP_COLOR.primary2Color, width: 1)),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: APP_COLOR.primary2Color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: const Text("Update Security", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStealthCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isStealthMode ? APP_COLOR.primary2Color.withOpacity(0.05) : Colors.transparent,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: APP_COLOR.primary2Color, borderRadius: BorderRadius.circular(50)),
                  child: Icon(Icons.psychology_alt, color: APP_COLOR.white),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Stealth Mode", style: TEXT_STYLE.textNavyBlack16w700),
                      Text("Hide app name as '$_selectedFakeName'", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Switch(
                  value: _isStealthMode,
                  activeColor: APP_COLOR.primary2Color,
                  onChanged: (val) => _updateStealthSettings(enabled: val),
                ),
              ],
            ),
          ),

          // যদি স্টিলথ মোড অন থাকে তবে ড্রপডাউন দেখাবে
          if (_isStealthMode) ...[
            Padding(
              padding: const EdgeInsets.all(25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Choose Alias Name:", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFakeName,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.blueGrey),
                      style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _updateStealthSettings(newName: newValue);
                        }
                      },
                      items: _fakeNames.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ],
      ),
    );
  }
}