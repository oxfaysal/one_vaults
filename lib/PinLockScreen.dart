import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HomePage.dart';
import 'conts/Color.dart';
import 'conts/TextStyle.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final TextEditingController _pinController = TextEditingController();
  String? _savedPin;
  bool _isChecking = true;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  // ফোন থেকে পিন চেক করা
  Future<void> _checkLockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _savedPin = prefs.getString('user_pin');

    // যদি পিন সেট করা না থাকে, সরাসরি হোমে চলে যাবে
    if (_savedPin == null || _savedPin!.isEmpty) {
      _enterApp();
    } else {
      setState(() => _isChecking = false);
    }
  }

  void _enterApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  // পিন ভেরিফাই করা (এটি ৪-৬ যেকোনো পিনের দৈর্ঘ্য অটো চেক করবে)
  void _verifyPin(String input) {
    if (_savedPin != null && input.length == _savedPin!.length) {
      if (input == _savedPin) {
        _enterApp();
      } else {
        _pinController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("ভুল পিন! আবার চেষ্টা করুন।"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: APP_COLOR.mainBG,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // টপ আইকন এনিমেশন বা ডিজাইন
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: APP_COLOR.primary2Color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_open_rounded, size: 60, color: APP_COLOR.primary2Color),
            ),
            const SizedBox(height: 30),

            Text("Welcome Back", style: TEXT_STYLE.textNavyBlack20w500),
            const SizedBox(height: 8),
            Text(
              "Unlock the app using your PIN",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // পিন ইনপুট বক্স
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: TextField(
                controller: _pinController,
                obscureText: _obscureText,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                onChanged: _verifyPin,
                style: const TextStyle(
                  fontSize: 26,
                  letterSpacing: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "••••••",
                  hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 10),
                  border: InputBorder.none,
                  // পাসওয়ার্ড দেখার বাটন
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                  prefixIcon: const Icon(Icons.fingerprint, color: Colors.transparent), // এলাইনমেন্ট ঠিক রাখার জন্য
                ),
              ),
            ),

            const SizedBox(height: 30),

            // নিচের টেক্সট
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("পিন ভুলে গেলে অ্যাপটি পুনরায় ইনস্টল করুন।")),
                );
              },
              child: Text(
                "Forgot PIN?",
                style: TextStyle(color: APP_COLOR.primary2Color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}