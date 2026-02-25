import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_vaults/conts/Color.dart';
import 'package:one_vaults/conts/TextStyle.dart';
import 'package:one_vaults/utils/input.dart';
import 'package:one_vaults/utils/isar_service.dart';
import 'package:one_vaults/utils/vault_model.dart';

class AllVaultsPage extends StatefulWidget {
  const AllVaultsPage({super.key});

  @override
  State<AllVaultsPage> createState() => _AllVaultsPageState();
}

class _AllVaultsPageState extends State<AllVaultsPage> {
  final service = IsarService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";
  String _selectedCategory = "All"; // ডিফল্ট ফিল্টার
  List<String> categories = ["All", "Browser", "Mobile", "Payment"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: APP_COLOR.mainBG,
      appBar: AppBar(
        title: Text("All Vaults", style: TEXT_STYLE.textNavyBlack20w500),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          decoration:BoxDecoration(
            color: APP_COLOR.white,
            borderRadius: BorderRadius.circular(50),
          ),
          child: IconButton(onPressed: (){
            Navigator.pop(context);
          }, icon: Icon(Icons.arrow_back)),
        ),
      ),
      body: Column(
        children: [
          // ১. সার্চ বার
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: inputField.formField(
              _searchController,
              "Search by brand name...",
              Icons.search,
                  (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
                  (value) {},
            ),
          ),

          // ২. ক্যাটাগরি ফিল্টার চিপস
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: categories.map((cat) {
                bool isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: APP_COLOR.primary2Color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // ৩. ভল্ট লিস্ট
          Expanded(
            child: FutureBuilder<List<Vault>>(
              future: service.getAllVaults(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No vaults saved yet."));
                }

                // ডাটা ফিল্টারিং লজিক (Search + Category)
                final filteredList = snapshot.data!.where((vault) {
                  final matchesSearch = (vault.brandName ?? "").toLowerCase().contains(_searchQuery);
                  final matchesCategory = _selectedCategory == "All" || vault.category == _selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredList.isEmpty) {
                  return const Center(child: Text("No matches found!"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
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
          ),
        ],
      ),
    );
  }

  // আইটেম কার্ড ডিজাইন (আপনার আগের ডিজাইন অনুযায়ী)
  Widget _itemCard(String iconUrl, String brandName, String username, String password) {
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
                    _copyToClipboard(username);
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
                    _copyToClipboard(password);
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password copied!")),
      );
    });
  }
}