import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:one_vaults/conts/Color.dart';
import 'package:one_vaults/conts/TextStyle.dart';
import 'package:window_manager/window_manager.dart';

import 'MediaPage/MediaPage.dart';
import 'utils/cardDesign.dart';
import 'utils/input.dart';
import 'utils/isar_service.dart';
import 'utils/vault_model.dart';

String iconUrl = "";
String capitalizedBrand = "";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final service = IsarService();
  late VaultUIHelper uiHelper;
  String _searchQuery = "";

  String _selectedCategory = "All";

  void _refreshData() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // ২. ইনপুট প্যারামিটার দিয়ে ইনিশিয়ালাইজ করুন
    uiHelper = VaultUIHelper(
      context: context,
      service: service, // আপনার IsarService
      onRefresh: () => setState(() {}), // রিফ্রেশ লজিক
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: APP_COLOR.mainBG,
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(gradient: APP_COLOR.topBG),
          child: Column(
            children: [

              if (!kIsWeb &&
                  (Platform.isWindows || Platform.isMacOS || Platform.isLinux))
                DragToMoveArea(
                  child: Container(
                    height: 38,
                    // একটু চিকন করলে বেশি মডার্ন লাগে
                    padding: const EdgeInsets.only(left: 16, right: 4),
                    // ডানপাশে বাটনের জন্য প্যাডিং কম
                    decoration: BoxDecoration(
                      color: Colors.transparent, // হালকা ট্রান্সপারেন্ট ডার্ক
                      border: const Border(
                        bottom: BorderSide(color: Colors.white10, width: 0.8),
                      ),
                    ),
                    child: Row(
                      children: [
                        // লোগো এবং টাইটেল সেকশন
                        Container(
                          width: 28,
                          // একটি নির্দিষ্ট সাইজ দিলে দেখতে ইউনিফর্ম লাগে
                          height: 28,
                          padding: const EdgeInsets.all(6),
                          // আইকনের চারপাশে একটু শ্বাস নেওয়ার জায়গা
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            // হালকা একটু বেশি অপাসিটি মডার্ন দেখায়
                            borderRadius: BorderRadius.circular(8),
                            // উইন্ডোজ ১১ স্টাইল কার্ভ
                            border: Border.all(
                                color: APP_COLOR.primary2Color.withOpacity(0.2),
                                width: 0.5
                            ),
                          ),
                          child: Image.asset(
                            "assets/icon/tray_icon.png",
                            fit: BoxFit.contain,
                            // ইমেজ যেন ফেটে না যায় বা কেটে না যায়
                            filterQuality: FilterQuality
                                .high, // ডেস্কটপে আইকন শার্প দেখাবে
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "One Vaults",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),

                        // উইন্ডোজ কন্ট্রোল বাটন (মডার্ন স্টাইল)
                        WindowCaptionButton.minimize(
                          brightness: Brightness.dark,
                          onPressed: () => windowManager.minimize(),
                        ),
                        // ক্লোজ বাটনে একটু লালচে আভা থাকে যা নেটিভ ফিল দেয়
                        WindowCaptionButton.close(
                          brightness: Brightness.dark,
                          onPressed: () => windowManager.close(),
                        ),
                      ],
                    ),
                  ),
                ),

              _buildHeader(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: APP_COLOR.mainBG,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),
                child: Column(
                  children: [
                    // ২. সার্চ বার (এটি FutureBuilder এর বাইরে থাকবে যাতে টাইপ করলে ডাটা ফিল্টার হয়)
                    inputField.formField(
                      _searchController,
                      "Search your vaults",
                      Icons.search,
                          (value) =>
                          setState(() => _searchQuery = value.toLowerCase()),
                          (value) {},
                    ),

                    const SizedBox(height: 22),

                    _buildMediaGrid(
                      onPhotosTap: () {
                        Navigator.pushNamed(context, "/mediaGallery", arguments: "Photos");
                      },
                      onVideosTap: () {
                        Navigator.pushNamed(context, "/mediaGallery", arguments: "Videos");
                      },
                      onAudioTap: () {
                        Navigator.pushNamed(context, "/mediaGallery", arguments: "Audio");
                      },
                      onFilesTap: () {
                        Navigator.pushNamed(context, "/mediaGallery", arguments: "Files");
                      },
                    ),

                    const SizedBox(height: 26),
                    FutureBuilder<List<Vault>>(
                      future: service.getAllVaults(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final allVaults = snapshot.data ?? [];

                        // ক্যাটাগরি অনুযায়ী ডাটা কাউন্ট করা
                        int browserCount = allVaults
                            .where((v) => v.category == "Browser")
                            .length;
                        int mobileCount = allVaults
                            .where((v) => v.category == "Mobile")
                            .length;
                        int paymentCount = allVaults
                            .where((v) => v.category == "Payment")
                            .length;

                        // লিস্ট ফিল্টারিং লজিক
                        final filteredVaults = allVaults.where((vault) {
                          final matchesSearch =
                              vault.brandName?.toLowerCase().contains(
                                _searchQuery,
                              ) ??
                                  true;
                          final matchesCategory =
                              _selectedCategory == "All" ||
                                  vault.category == _selectedCategory;
                          return matchesSearch && matchesCategory;
                        }).toList();

                        return Column(
                          children: [
                            // ৪. ক্যাটাগরি রো (কাউন্ট সহ)
                            Row(
                              spacing: 10,
                              children: [
                                _categoryItem(
                                  FontAwesomeIcons.link,
                                  "Browser",
                                  "${browserCount.toString().padLeft(
                                      2, '0')} Items",
                                      () {
                                    setState(
                                          () =>
                                      _selectedCategory =
                                      _selectedCategory == "Browser"
                                          ? "All"
                                          : "Browser",
                                    );
                                  },
                                ),
                                _categoryItem(
                                  FontAwesomeIcons.mobile,
                                  "Mobile",
                                  "${mobileCount.toString().padLeft(
                                      2, '0')} Items",
                                      () {
                                    setState(
                                          () =>
                                      _selectedCategory =
                                      _selectedCategory == "Mobile"
                                          ? "All"
                                          : "Mobile",
                                    );
                                  },
                                ),
                                _categoryItem(
                                  FontAwesomeIcons.creditCard,
                                  "Payment",
                                  "${paymentCount.toString().padLeft(
                                      2, '0')} Items",
                                      () {
                                    setState(
                                          () =>
                                      _selectedCategory =
                                      _selectedCategory == "Payment"
                                          ? "All"
                                          : "Payment",
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // ৫. রিসেন্টলি ইউজড হেডার
                            _buildListHeader(),

                            const SizedBox(height: 16),

                            // ৬. ফিল্টার করা লিস্ট
                            filteredVaults.isEmpty
                                ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text("No matches found"),
                              ),
                            )
                                : ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              physics:
                              const NeverScrollableScrollPhysics(),
                              itemCount: filteredVaults.length,
                              itemBuilder: (context, index) {
                                return uiHelper.buildVaultCard(
                                  filteredVaults[index],
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: APP_COLOR.primary2Color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        onPressed: () async {
          var result = await Navigator.pushNamed(context, "/addVault");
          if (result == true) _refreshData();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // হেডার উইজেট
  Widget _buildHeader() {
    double topPadding =
    (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux)
        ? 20
        : 60;
    return Container(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: topPadding,
        bottom: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Assalamualikum 😊", style: TEXT_STYLE.textWhite20),
              Text("Welcome back again!", style: TEXT_STYLE.textWhite14),
            ],
          ),
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, "/settings");
            },
            child: _iconItem(
              40,
              FontAwesomeIcons.gear,
              APP_COLOR.white,
              20,
              1,
              50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid({
    required VoidCallback onPhotosTap,
    required VoidCallback onVideosTap,
    required VoidCallback onFilesTap,
    required VoidCallback onAudioTap,
  }) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _mediaItem(
            FontAwesomeIcons.solidImage, "Photos", Colors.blue, onPhotosTap),
        _mediaItem(FontAwesomeIcons.video, "Videos", Colors.red, onVideosTap),
        _mediaItem(FontAwesomeIcons.music, "Audio", Colors.purple, onAudioTap),
        _mediaItem(
            FontAwesomeIcons.fileLines, "Files", Colors.orange, onFilesTap),
      ],
    );
  }

  Widget _mediaItem(IconData icon, String label, Color color,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      // ক্লিক করার সময় সুন্দর রাউন্ডেড শেপ হবে
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: color.withOpacity(0.05), width: 1),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
          ),
          const SizedBox(height: 8),
          Text(
              label,
              style: const TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)
          ),
        ],
      ),
    );
  }

  // লিস্ট হেডার
  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Recently Used", style: TEXT_STYLE.textNavyBlack16w700),
        InkWell(
          onTap: () => Navigator.pushNamed(context, "/allVault"),
          child: Text("See More", style: TEXT_STYLE.textGray10),
        ),
      ],
    );
  }

  Widget _categoryItem(IconData icon,
      String title,
      String subtitle, // এখানে আপনি আইটেম সংখ্যা পাঠাচ্ছেন (যেমন: "05 Items")
      VoidCallback onTap,) {
    bool isSelected = _selectedCategory == title;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            // উপরের বক্সটি (আইকন কন্টেইনার)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 60,
              // ফিক্সড হাইট দিলে সবগুলো ইউনিফর্ম দেখাবে
              width: double.infinity,
              decoration: BoxDecoration(
                // সিলেক্ট হলে সলিড কালার, না হলে খুব হালকা শেড
                color: isSelected
                    ? APP_COLOR.primary2Color
                    : APP_COLOR.primary2Color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? APP_COLOR.primary2Color : Colors.black
                      .withOpacity(0.03),
                  width: 1,
                ),
              ),
              child: Center(
                child: FaIcon(
                  icon,
                  color: isSelected ? Colors.white : APP_COLOR.primary2Color,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // টেক্সট সেকশন
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle, // আপনার "02 Items" লেখাটি এখানে ছোট করে দেখাবে
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? APP_COLOR.primary2Color : Colors.grey
                    .shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconItem(double size,
      IconData icon,
      Color iconColor,
      double iconSize,
      double bgOpacity,
      double radius,) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: APP_COLOR.primaryColor.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: FaIcon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}
