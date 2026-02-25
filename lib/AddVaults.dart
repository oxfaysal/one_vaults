import 'package:flutter/material.dart';
import 'package:one_vaults/utils/input.dart';
import 'HomePage.dart';
import 'conts/TextStyle.dart';
import 'conts/Color.dart';
import 'utils/isar_service.dart';
import 'utils/vault_model.dart';

class AddVaults extends StatefulWidget {
  AddVaults({super.key});

  @override
  State<AddVaults> createState() => _AddVaultsState();
}

class _AddVaultsState extends State<AddVaults> {

  Vault? existingVault;

  final TextEditingController _urlController = TextEditingController();

  final TextEditingController _userController = TextEditingController();

  final TextEditingController _passController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _noteController = TextEditingController();

  String getDomain(String url) {
    if (url.isEmpty) return "";

    // যদি ইউজার http না লেখে, তবে সেটি যোগ করে নিতে হবে
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http')) {
      formattedUrl = 'https://$formattedUrl';
    }

    try {
      var uri = Uri.parse(formattedUrl);
      return uri.host; // যেমন: www.netflix.com
    } catch (e) {
      return "";
    }
  }

  void _updateIcon(String value) {
    String domain = getDomain(value);
    String brandName = getBrandName(value);
    if (domain.isNotEmpty) {
      setState(() {
        // আইকন আপডেট
        iconUrl = "https://www.google.com/s2/favicons?sz=64&domain=$domain";

        // ব্র্যান্ড নেম আপডেট এবং ক্যাপিটালাইজ করা
        capitalizedBrand = brandName.isNotEmpty
            ? brandName[0].toUpperCase() + brandName.substring(1)
            : "";
      });
    }
  }

  String getBrandName(String url) {
    if (url.isEmpty) return "";

    String formattedUrl = url.trim().toLowerCase();
    if (!formattedUrl.startsWith('http')) {
      formattedUrl = 'https://$formattedUrl';
    }

    try {
      var uri = Uri.parse(formattedUrl);
      String host = uri.host; // আউটপুট আসবে: www.netflix.com বা netflix.com

      // এবার www. এবং .com অংশগুলো বাদ দেওয়ার পালা
      List<String> parts = host.split('.');

      if (parts.length >= 2) {
        // যদি www থাকে (www.netflix.com), তবে ২য় অংশটি নিবে (netflix)
        if (parts[0] == 'www') {
          return parts[1];
        } else {
          // যদি www না থাকে (netflix.com), তবে ১ম অংশটি নিবে (netflix)
          return parts[0];
        }
      }
      return host;
    } catch (e) {
      return "";
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Vault && existingVault == null) {
      existingVault = args;
      _urlController.text = args.siteUrl ?? "";
      _userController.text = args.username ?? "";
      _passController.text = args.password ?? "";
      _phoneController.text = args.phone ?? "";
      _noteController.text = args.note ?? "";
      selectedCategory = args.category ?? 'Browser';
      iconUrl = args.iconUrl ?? "";
    }
  }

  String selectedCategory = 'Browser';
  List<String> categories = ['Browser', 'Mobile', 'Payment'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: APP_COLOR.mainBG,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: Text(existingVault == null ? "Create new vault" : "Update old vault", style: TEXT_STYLE.textNavyBlack20w500),
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
            child: IconButton(
                onPressed: (){
              Navigator.pop(context);
            }, icon: Icon(Icons.arrow_back, size: 20,)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: APP_COLOR.white,
                borderRadius: BorderRadius.circular(100),
                image: iconUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(iconUrl),
                  scale: 1.8,
                )
                    : null,
              ),
              child: iconUrl.isEmpty
                  ? Icon(Icons.language, size: 30, color: APP_COLOR.colorGray)
                  : null,
            ),

            SizedBox(height: 22,),

            Container(
              decoration: BoxDecoration(
                color: APP_COLOR.white,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Credential", style: TEXT_STYLE.textNavyBlack16w700,),
                  SizedBox(height: 24,),

                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: "Select Category",
                      prefixIcon: Icon(Icons.category, color: APP_COLOR.colorGray),
                      filled: true,
                      fillColor: APP_COLOR.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: APP_COLOR.colorGray.withOpacity(0.2)),
                      ),
                    ),
                    items: categories.map((String category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedCategory = newValue!;
                      });
                    },
                  ),
                  SizedBox(height: 22,),
                  inputField.formField(_urlController, "Site Address", Icons.link, (value){
                    setState(() {
                      _updateIcon(value);
                    });
                  }, (value){}),
                  SizedBox(height: 22,),
                  inputField.formField(_userController, "User Name", Icons.person, (value){}, (value){}),
                  SizedBox(height: 22,),
                  inputField.formField(_passController, "Password", Icons.lock, (value){}, (value){}),
                  SizedBox(height: 22,),
                  inputField.formField(_phoneController, "Phone Number (Optional)", Icons.call, (value){}, (value){}),
                  SizedBox(height: 22,),
                  inputField.formField(_noteController, "Note (Optional)", Icons.note_add, (value){}, (value){}),



                ],
              ),
            ),

            SizedBox(height: 30,),

            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_urlController.text.isNotEmpty) {
                      final service = IsarService();
                      String domain = getDomain(_urlController.text);
                      String brand = getBrandName(_urlController.text);

                      final vaultToSave = Vault()
                        ..siteUrl = _urlController.text
                        ..brandName = brand.isNotEmpty ? brand[0].toUpperCase() + brand.substring(1) : "Unknown"
                        ..iconUrl = "https://www.google.com/s2/favicons?sz=64&domain=$domain"
                        ..username = _userController.text
                        ..password = _passController.text
                        ..phone = _phoneController.text
                        ..category = selectedCategory
                        ..note = _noteController.text;

                      if (existingVault != null) {
                        vaultToSave.id = existingVault!.id;
                      }
                      await service.saveVault(vaultToSave);
                      Navigator.pop(context, true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    backgroundColor: APP_COLOR.primary2Color, foregroundColor: APP_COLOR.white),
                  child: Text(
                    existingVault == null ? "Create the vault" : "Update the vault",
                    style: TEXT_STYLE.textWhite14,
                  ),
                ),
              ),
            ),




          ],
        ),
      ),
    );
  }
}
