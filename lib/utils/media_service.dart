import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class MediaService {
  Future<Directory> getSafeDirectory(String type) async {
    Directory baseDir;
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      baseDir = await getApplicationSupportDirectory();
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    // লুকানো ফোল্ডার তৈরি (নামের আগে ডট দিলে ফাইল ম্যানেজারেও সহজে দেখা যায় না)
    final String folderPath = p.join(baseDir.path, '.onevaults', type.toLowerCase());
    final Directory typeDir = Directory(folderPath);

    if (!await typeDir.exists()) {
      await typeDir.create(recursive: true);

      // গ্যালারি থেকে হাইড করার জন্য .nomedia ফাইল তৈরি
      if (!kIsWeb && Platform.isAndroid) {
        final noMedia = File(p.join(typeDir.path, '.nomedia'));
        if (!await noMedia.exists()) await noMedia.create();
      }
    }
    return typeDir;
  }

  // ২. ফাইল ভল্টে আনা এবং সোর্স ডিলিট করা
  Future<File?> importFile(File sourceFile, String type) async {
    try {
      final directory = await getSafeDirectory(type);
      final String fileName = "vault_${DateTime.now().millisecondsSinceEpoch}_${p.basenameWithoutExtension(sourceFile.path)}.sav";
      final String newPath = p.join(directory.path, fileName);

      // ১. প্রথমে ফাইলটি ভল্টে কপি করুন
      final File copiedFile = await sourceFile.copy(newPath);

      // ২. কপি সফল হলে ডিলিট করার চেষ্টা করুন
      if (await copiedFile.exists()) {
        if (Platform.isAndroid) {
          try {
            // অ্যান্ড্রয়েডে সরাসরি ডিলিট কাজ না করলে এটি ট্রাই করুন
            await sourceFile.delete();
          } catch (e) {
            debugPrint("Direct delete failed, trying alternative...");
            // অনেক সময় ফাইল সিস্টেম বিজি থাকে, তাই ছোট একটি ডিলে দিয়ে আবার চেষ্টা করা যায়
            await Future.delayed(const Duration(milliseconds: 200));
            if (await sourceFile.exists()) {
              await sourceFile.delete();
            }
          }
        } else {
          // ডেস্কটপে আগের মতোই কাজ করবে
          await sourceFile.delete();
        }
      }

      return copiedFile;
    } catch (e) {
      debugPrint("Error importing file: $e");
      return null;
    }
  }

  // ৩. ফাইল আবার এক্সপোর্ট করা (গ্যালারিতে পাঠানো)
  Future<bool> exportFile(String filePath, String type) async {
    try {
      File file = File(filePath);
      if (!await file.exists()) return false;

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // সেভ করার আগে একটি টেম্পোরারি ফাইলে অরিজিনাল এক্সটেনশন ফেরত আনা
        String originalExt = (type.toLowerCase() == 'photos') ? ".jpg" : ".mp4";
        if (type.toLowerCase() == 'audio') originalExt = ".mp3";

        final tempDir = await getTemporaryDirectory();
        final tempPath = p.join(tempDir.path, "export_${DateTime.now().millisecondsSinceEpoch}$originalExt");
        File tempFile = await file.copy(tempPath);

        if (type.toLowerCase() == 'photos') {
          await GallerySaver.saveImage(tempFile.path, albumName: "OneVaults");
        } else if (type.toLowerCase() == 'videos') {
          await GallerySaver.saveVideo(tempFile.path, albumName: "OneVaults");
        }

        // কাজ শেষ হলে টেম্প ফাইল ডিলিট
        await tempFile.delete();
        return true;
      }

      // ডেস্কটপের জন্য ডাউনলোড ফোল্ডারে পাঠানো
      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        final downloadDir = await getDownloadsDirectory();
        if (downloadDir != null) {
          final String fileName = p.basename(filePath).replaceFirst(RegExp(r'vault_\d+_'), '').replaceAll('.sav', '');
          final String exportPath = p.join(downloadDir.path, fileName);
          await file.copy(exportPath);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("Export error: $e");
      return false;
    }
  }



  Future<bool> checkStoragePermission() async {

    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
    return true;
  }


}

