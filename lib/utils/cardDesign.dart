import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_vaults/conts/Color.dart';
import 'package:one_vaults/conts/TextStyle.dart';
import 'package:one_vaults/utils/vault_model.dart';
import 'package:one_vaults/utils/isar_service.dart';

class VaultUIHelper {
  final BuildContext context;
  final IsarService service;
  final VoidCallback onRefresh;

  VaultUIHelper({
    required this.context,
    required this.service,
    required this.onRefresh,
  });

  // --- মেইন কার্ড ডিজাইন ---
  Widget buildVaultCard(Vault item) {
    return InkWell(
      hoverColor: Colors.transparent,
      onTap: () => _showDetailsDialog(
        item.iconUrl ?? "",
        item.brandName ?? "",
        item.username ?? "",
        item.password ?? "",
        item.phone,
        item.note,
      ),
      child: Card(
        color: APP_COLOR.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                height: 55, width: 55,
                decoration: BoxDecoration(
                  color: APP_COLOR.mainBG,
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(item.iconUrl ?? ""),
                    scale: 1.8,
                    onError: (_, __) => const Icon(Icons.broken_image),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.brandName ?? "No Name", style: TEXT_STYLE.textNavyBlack16w700),
                    Text(item.username ?? "", style: TEXT_STYLE.searchingTextBold),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: APP_COLOR.colorGray), // আরও সফট আইকন
                offset: const Offset(0, 45), // মেনুটিকে আইকনের একটু নিচে দেখাবে
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: APP_COLOR.primary2Color.withOpacity(0.2))
                ),
                color: Colors.white,
                onSelected: (value) {
                  if (value == 'edit') {
                    _editVault(item);
                  } else if (value == 'delete') {
                    _showDeleteConfirmDialog(item.id);
                  }
                },
                itemBuilder: (context) => [
                  // এডিট অপশন
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.blue, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text("Edit", style: TEXT_STYLE.textNavyBlack14w700),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Delete",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- এডিট লজিক ---
  void _editVault(Vault item) async {
    var result = await Navigator.pushNamed(context, "/addVault", arguments: item);
    if (result == true) onRefresh();
  }

  // --- ডিলিট লজিক ---
  void _showDeleteConfirmDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ১. টপ আইকন (ডেঞ্জার সাইন)
              Container(
                height: 60, width: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 35),
              ),
              const SizedBox(height: 20),

              // ২. টেক্সট সেকশন
              const Text(
                "Are you sure?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Text(
                "Do you really want to delete this vault? This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 25),

              // ৩. একশন বাটনস
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Delete Button
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await service.deleteVault(id);
                        Navigator.pop(context);
                        onRefresh();

                        // সাকসেস মেসেজ (Optional)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Vault deleted successfully"), backgroundColor: Colors.red),
                        );
                      },
                      child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- বিস্তারিত ডায়ালগ ---
  void _showDetailsDialog(String iconUrl, String brand, String user, String pass, String? phone, String? note) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 40),
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(brand, style: TEXT_STYLE.textNavyBlack16w700.copyWith(fontSize: 22)),
                    const SizedBox(height: 5),
                    Text("Account Details", style: TEXT_STYLE.textGray10.copyWith(fontSize: 12)),
                    const Divider(height: 30),
                    _buildInfoTile("Username", user, Icons.person_rounded),
                    const SizedBox(height: 12),
                    _buildInfoTile("Password", pass, Icons.vpn_key_rounded),
                    if (phone != null && phone.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoTile("Phone Number", phone, Icons.phone_android_rounded),
                    ],
                    if (note != null && note.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildNoteSec(note),
                    ],
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: APP_COLOR.mainBG,
                          foregroundColor: APP_COLOR.primary2Color,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildFloatingIcon(iconUrl),
          ],
        ),
      ),
    );
  }

  // --- সাব-উইজেটসমূহ (প্রাইভেট) ---
  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: APP_COLOR.mainBG.withOpacity(0.5), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Icon(icon, color: APP_COLOR.primary2Color, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TEXT_STYLE.textGray10.copyWith(fontSize: 10)),
                Text(value, style: TEXT_STYLE.textNavyBlack14w700),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copy(value),
            icon: Icon(Icons.copy_all_rounded, color: APP_COLOR.colorGray, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSec(String note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Note", style: TEXT_STYLE.textGray10.copyWith(fontSize: 12)),
        const SizedBox(height: 5),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
          child: SelectableText(note, style: TEXT_STYLE.searchingText.copyWith(fontSize: 13, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  Widget _buildFloatingIcon(String url) {
    return Positioned(
      top: 0,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Container(
          height: 80, width: 80,
          decoration: BoxDecoration(
            color: APP_COLOR.mainBG, shape: BoxShape.circle,
            image: DecorationImage(image: NetworkImage(url), scale: 1.2),
          ),
        ),
      ),
    );
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied!")));
    });
  }
}