import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'vault_model.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [VaultSchema, MediaVaultSchema],
        directory: dir.path,
      );
    }
    return Isar.getInstance()!;
  }

  // ডাটা সেভ করার জন্য
  Future<void> saveVault(Vault newVault) async {
    final isar = await db;
    isar.writeTxnSync(() => isar.vaults.putSync(newVault));
  }

  // সব ডাটা লিস্ট আকারে পাওয়ার জন্য
  Future<List<Vault>> getAllVaults() async {
    final isar = await db;
    return await isar.vaults.where().findAll();
  }

  Future<void> deleteVault(int id) async {
    final isar = await db;
    await isar.writeTxn(() => isar.vaults.delete(id));
  }


}