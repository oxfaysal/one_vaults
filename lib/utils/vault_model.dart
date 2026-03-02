import 'package:isar/isar.dart';

part 'vault_model.g.dart';

@collection
class Vault {
  Id id = Isar.autoIncrement; // অটো আইডি

  String? siteUrl;
  String? brandName;
  String? iconUrl;
  String? username;
  String? password;
  String? phone;
  String? category;
  String? note;
}


@collection
class MediaVault {
  Id id = Isar.autoIncrement;
  late String filePath; // এনক্রিপ্টেড বা হিডেন পাথ
  late String fileName;
  late String fileType; // 'photo', 'video', 'audio', 'file'
  late DateTime dateAdded;
}