import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _obscureText = true; // পাসওয়ার্ড লুকানোর জন্য

  @override
  void initState() {
    super.initState();
    _loadCurrentPin();
  }

  // বর্তমানে পিন সেট করা আছে কি না দেখা
  Future<void> _loadCurrentPin() async {
    final prefs = await SharedPreferences.getInstance();
    String? pin = prefs.getString('user_pin');
    if (pin != null && pin.isNotEmpty) {
      setState(() {
        _isLockEnabled = true;
        _pinController.text = pin;
      });
    }
  }

  // পিন সেভ বা রিমুভ করা
  Future<void> _handleSave() async {
    final prefs = await SharedPreferences.getInstance();
    String newPin = _pinController.text.trim();

    if (newPin.isEmpty) {
      // পিন খালি থাকলে লক রিমুভ হবে
      await prefs.remove('user_pin');
      setState(() => _isLockEnabled = false);
      _showSnack("পিন লক বন্ধ করা হয়েছে", Colors.orange, Icons.lock_open);
    } else if (newPin.length >= 4 && newPin.length <= 6) {
      // পিন ৪ থেকে ৬ ডিজিটের হলে সেভ হবে
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
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(msg),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
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
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: APP_COLOR.white,
              borderRadius: BorderRadius.circular(50),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 20),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // প্রিমিয়াম সিকিউরিটি কার্ড
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  // কার্ডের উপরের অংশ
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: APP_COLOR.primary2Color.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: APP_COLOR.primary2Color,
                          child: const Icon(Icons.shield, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("App Lock Security", style: TEXT_STYLE.textNavyBlack16w700),
                              Text(
                                _isLockEnabled ? "Your app is now secure" : "Lock is not set",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
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

                  // কার্ডের বডি
                  Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Set Security PIN (4-6 Digits)",
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
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
                              icon: Icon(
                                _obscureText ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: APP_COLOR.primary2Color, width: 1),
                            ),
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
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: const Text(
                              "Update Security",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}