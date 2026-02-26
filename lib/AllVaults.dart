import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_vaults/conts/Color.dart';
import 'package:one_vaults/conts/TextStyle.dart';
import 'package:one_vaults/utils/input.dart';
import 'package:one_vaults/utils/isar_service.dart';
import 'package:one_vaults/utils/vault_model.dart';

import 'utils/cardDesign.dart';

class AllVaultsPage extends StatefulWidget {
  const AllVaultsPage({super.key});

  @override
  State<AllVaultsPage> createState() => _AllVaultsPageState();
}

class _AllVaultsPageState extends State<AllVaultsPage> {
  final service = IsarService();
  final TextEditingController _searchController = TextEditingController();
  late VaultUIHelper uiHelper;

  String _searchQuery = "";
  String _selectedCategory = "All"; // ডিফল্ট ফিল্টার
  List<String> categories = ["All", "Browser", "Mobile", "Payment"];

  @override
  void initState() {
    super.initState();
    uiHelper = VaultUIHelper(
      context: context,
      service: service,
      onRefresh: () => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: APP_COLOR.mainBG,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: Text("All Vaults", style: TEXT_STYLE.textNavyBlack20w500),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Center(
          child: Container(
            height: 40,
            width: 40,
            decoration:BoxDecoration(
              color: APP_COLOR.white,
              borderRadius: BorderRadius.circular(50),
            ),
            child: IconButton(onPressed: (){
              Navigator.pop(context);
            }, icon: Icon(Icons.arrow_back, size: 20,)),
          ),
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
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    // টেক্সট স্টাইল
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                    // চিপের ভেতরের স্পেসিং
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                    // রঙ সেট করা
                    selectedColor: APP_COLOR.primary2Color,
                    backgroundColor: APP_COLOR.white,

                    // ডিফল্ট ধূসর রঙের বর্ডার এবং শ্যাডো বাদ দেওয়া
                    elevation: isSelected ? 4 : 0,
                    pressElevation: 0,
                    shadowColor: APP_COLOR.primary2Color.withOpacity(0.3),

                    // বর্ডার ডিজাইন
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25), // চিপটিকে পুরোপুরি রাউন্ড করবে
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),

                    // ক্লিক করলে আসা ডিফল্ট নীল গোল ইফেক্ট বন্ধ করা
                    showCheckmark: false, // সিলেক্ট করলে যে টিক মার্ক আসে সেটি বন্ধ করা (মডার্ন লুকের জন্য)
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                    return uiHelper.buildVaultCard(filteredList[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}