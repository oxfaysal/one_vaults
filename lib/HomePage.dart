import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:one_vaults/conts/Color.dart';
import 'package:one_vaults/conts/TextStyle.dart';

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
              // ১. হেডার সেকশন (আসসালামু আলাইকুম)
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

                    const SizedBox(height: 12),

                    // ৩. FutureBuilder শুরু (এটির ভেতরে ক্যাটাগরি এবং লিস্ট থাকবে)
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
                                  "${browserCount.toString().padLeft(2, '0')} Items",
                                  () {
                                    setState(
                                      () => _selectedCategory =
                                          _selectedCategory == "Browser"
                                          ? "All"
                                          : "Browser",
                                    );
                                  },
                                ),
                                _categoryItem(
                                  FontAwesomeIcons.mobile,
                                  "Mobile",
                                  "${mobileCount.toString().padLeft(2, '0')} Items",
                                  () {
                                    setState(
                                      () => _selectedCategory =
                                          _selectedCategory == "Mobile"
                                          ? "All"
                                          : "Mobile",
                                    );
                                  },
                                ),
                                _categoryItem(
                                  FontAwesomeIcons.creditCard,
                                  "Payment",
                                  "${paymentCount.toString().padLeft(2, '0')} Items",
                                  () {
                                    setState(
                                      () => _selectedCategory =
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

  Widget _categoryItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    bool isSelected = _selectedCategory == title;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: APP_COLOR.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? APP_COLOR.primary2Color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              _iconItem(50, icon, APP_COLOR.primary2Color, 24, 0.1, 50),
              SizedBox(height: 12),
              Text(title, style: TEXT_STYLE.textNavyBlack14w700),
              SizedBox(height: 4),
              Text(subtitle, style: TEXT_STYLE.textGray10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconItem(
    double size,
    IconData icon,
    Color iconColor,
    double iconSize,
    double bgOpacity,
    double radius,
  ) {
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
