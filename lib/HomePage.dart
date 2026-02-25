import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:one_vaults/conts/Color.dart';
import 'package:one_vaults/conts/TextStyle.dart';

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
  String _searchQuery = "";

  void _refreshData() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: APP_COLOR.mainBG,
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(gradient: APP_COLOR.topBG),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.only(
                  left: 22,
                  right: 22,
                  top: 60,
                  bottom: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Assalamualikum 😊",
                          style: TEXT_STYLE.textWhite20,
                        ),
                        Text(
                          "Welcome back again!",
                          style: TEXT_STYLE.textWhite14,
                        ),
                      ],
                    ),
                    _iconItem(
                      40,
                      FontAwesomeIcons.gear,
                      APP_COLOR.white,
                      20,
                      1,
                      50,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: APP_COLOR.mainBG,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),
                child: Column(
                  children: [
                    inputField.formField(
                      _searchController,
                      "Search you vaults",
                      Icons.search,
                      (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      (value) {},
                    ),

                    SizedBox(height: 12),

                    Row(
                      spacing: 10,
                      children: [
                        _categoryItem(
                          FontAwesomeIcons.link,
                          "Browser",
                          "18 Passwords",
                        ),
                        _categoryItem(
                          FontAwesomeIcons.mobile,
                          "Mobile APP",
                          "12 Passwords",
                        ),
                        _categoryItem(
                          FontAwesomeIcons.creditCard,
                          "Payment",
                          "12 Passwords",
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recently Used",
                          style: TEXT_STYLE.textNavyBlack16w700,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, "/allVault");
                          },
                          child: Text("See More", style: TEXT_STYLE.textGray10),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    FutureBuilder<List<Vault>>(
                      future: service.getAllVaults(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              "No vaults found",
                              style: TEXT_STYLE.textGray10,
                            ),
                          );
                        }

                        // ব্র্যান্ড নেম অনুযায়ী লিস্ট ফিল্টার করা হচ্ছে
                        final allVaults = snapshot.data!;
                        final filteredVaults = allVaults.where((vault) {
                          final name = vault.brandName?.toLowerCase() ?? "";
                          return name.contains(_searchQuery);
                        }).toList();

                        if (filteredVaults.isEmpty) {
                          return Center(
                            child: Text(
                              "No matches found",
                              style: TEXT_STYLE.textGray10,
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredVaults.length,
                          itemBuilder: (context, index) {
                            final item = filteredVaults[index];
                            return _itemCard(
                              item.iconUrl ?? "",
                              item.brandName ?? "No Name",
                              item.username ?? "",
                              item.password ?? "",
                            );
                          },
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
      floatingActionButton: GestureDetector(
        onTap: () async {
          var result = await Navigator.pushNamed(context, "/addVault");
          if (result == true) {
            _refreshData();
          }
        },
        child: _iconItem(60, FontAwesomeIcons.add, APP_COLOR.white, 20, 1, 50),
      ),
    );
  }

  Widget _categoryItem(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: APP_COLOR.white,
          borderRadius: BorderRadius.circular(15),
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

  Widget _itemCard(
    String iconUrl,
    String brandName,
    String username,
    String password,
  ) {
    return Card(
      color: APP_COLOR.white,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          spacing: 10,
          children: [
            Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: APP_COLOR.mainBG,
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(iconUrl),
                  scale: 1.8,
                  onError: (exception, stackTrace) =>
                      CircularProgressIndicator(),
                ),
              ),
            ),

            Column(
              spacing: 5,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(brandName, style: TEXT_STYLE.textNavyBlack16w700),
                GestureDetector(
                  onTap: () {
                    _copyToClipboard(context, username);
                  },
                  child: Row(
                    spacing: 10,
                    children: [
                      Text(username, style: TEXT_STYLE.searchingTextBold),
                      Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: APP_COLOR.colorGray,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _copyToClipboard(context, password);
                  },
                  child: Row(
                    spacing: 10,
                    children: [
                      Text(password, style: TEXT_STYLE.searchingText),
                      Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: APP_COLOR.colorGray,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Copied to clipboard",
            style: TEXT_STYLE.textNavyBlack14w700,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: APP_COLOR.white,
          elevation: 0,
          duration: Duration(seconds: 2),
        ),
      );
    });
  }
}
