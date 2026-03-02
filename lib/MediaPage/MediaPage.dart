import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:one_vaults/utils/media_service.dart';
import 'package:one_vaults/conts/Color.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import 'AudioPlayerPage.dart';
import 'ImageViewerPage.dart';
import 'VideoPlayerScreen.dart';

class MediaGalleryPage extends StatefulWidget {
  final String type; // Photos, Videos, Audio, Files
  const MediaGalleryPage({super.key, required this.type});

  @override
  State<MediaGalleryPage> createState() => _MediaGalleryPageState();
}

class _MediaGalleryPageState extends State<MediaGalleryPage> {
  final MediaService _mediaService = MediaService();
  List<File> _files = [];
  bool _isLoading = true;

  // সিলেকশন মোডের জন্য ভেরিয়েবল
  final Set<int> _selectedIndexes = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadVaultFiles();
  }

  // ক্যাটাগরি অনুযায়ী ফাইল লোড করা
  Future<void> _loadVaultFiles() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final dir = await _mediaService.getSafeDirectory(widget.type);
    final List<FileSystemEntity> entities = dir.listSync();

    setState(() {
      _files = entities
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith('vault_'))
          .toList();
      _isLoading = false;
      _clearSelection(); // নতুন করে লোড হলে সিলেকশন ক্লিয়ার হবে
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIndexes.clear();
      _isSelectionMode = false;
    });
  }

  // বালক ডিলিট হ্যান্ডেলার
  void _handleBulkDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete ${_selectedIndexes.length} files?"),
        content: const Text("This action will permanently remove these files from your vault."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              List<int> sorted = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));
              for (var index in sorted) {
                await _files[index].delete();
              }
              Navigator.pop(context);
              _loadVaultFiles();
              _showSnackBar("${sorted.length} files deleted.");
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // বালক শেয়ার হ্যান্ডেলার
  void _handleBulkShare() {
    List<XFile> filesToShare = _selectedIndexes.map((i) => XFile(_files[i].path)).toList();
    Share.shareXFiles(filesToShare);
    _clearSelection();
  }

  // বালক এক্সপোর্ট হ্যান্ডেলার
  void _handleBulkExport() async {
    int count = 0;
    for (var index in _selectedIndexes) {
      bool ok = await _mediaService.exportFile(_files[index].path, widget.type);
      if (ok) count++;
    }
    _showSnackBar("$count files exported successfully!");
    _clearSelection();
  }

  Future<void> _addFile() async {
    // ১. প্রথমেই স্টোরেজ পারমিশন চেক (MANAGE_EXTERNAL_STORAGE)
    bool hasPermission = await _mediaService.checkStoragePermission();

    if (!hasPermission) {
      _showSnackBar("Required Android Permission to hide files");
      await openAppSettings();
      return;
    }

    // ২. ফাইল পিকার ওপেন করা
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: widget.type == "Photos" ? FileType.image :
      widget.type == "Videos" ? FileType.video :
      widget.type == "Audio" ? FileType.audio : FileType.any,
    );

    // ৩. যদি ইউজার ফাইল সিলেক্ট করে থাকে
    if (result != null && result.files.isNotEmpty) {
      setState(() => _isLoading = true);

      try {
        int successCount = 0;

        // ৪. লুপ চালিয়ে প্রতিটি ফাইল ইমপোর্ট করা
        for (var filePlatform in result.files) {
          if (filePlatform.path != null) {
            File sourceFile = File(filePlatform.path!);

            // ফাইলটি ভল্টে পাঠানো (এটি মিডিয়া সার্ভিস থেকে সোর্স ডিলিট করে দিবে)
            var importedFile = await _mediaService.importFile(sourceFile, widget.type);

            if (importedFile != null) {
              successCount++;
            }
          }
        }

        // ৫. লিস্ট আপডেট এবং রেজাল্ট দেখানো
        await _loadVaultFiles();
        _showSnackBar("$successCount files safely moved to vault!");

      } catch (e) {
        debugPrint("Add File Error: $e");
        _showSnackBar("Something went wrong while adding files.");
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: APP_COLOR.mainBG,
        appBar: AppBar(
          title: Text(_isSelectionMode ? "${_selectedIndexes.length} Selected" : widget.type,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          leading: _isSelectionMode
              ? IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection)
              : null,
          actions: [
            if (_isSelectionMode) ...[
              IconButton(icon: const Icon(Icons.share), onPressed: _handleBulkShare),
              IconButton(icon: const Icon(Icons.file_download_outlined), onPressed: _handleBulkExport),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _handleBulkDelete),
            ] else
              IconButton(
                  onPressed: _addFile,
                  icon: Icon(Icons.add_box_rounded, color: APP_COLOR.primary2Color, size: 28)
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _files.isEmpty
            ? _buildEmptyUI()
            : GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 140,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: _files.length,
          itemBuilder: (context, index) => _buildMediaCard(_files[index], index),
        )
    );
  }

  Widget _buildMediaCard(File file, int index) {
    bool isSelected = _selectedIndexes.contains(index);
    String fileName = p.basename(file.path).replaceFirst(RegExp(r'vault_\d+_'), '');

    return GestureDetector(
      onLongPress: () {
        Feedback.forLongPress(context);
        setState(() {
          _isSelectionMode = true;
          _selectedIndexes.add(index);
        });
      },
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedIndexes.remove(index);
              if (_selectedIndexes.isEmpty) _isSelectionMode = false;
            } else {
              _selectedIndexes.add(index);
            }
          });
        } else {
          if (widget.type == "Photos") {
            _viewImage(index);
          } else if (widget.type == "Videos") {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(file: file),
            ));
          } else if (widget.type == "Audio") {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => AudioPlayerPage(playlist: _files, initialIndex: index),
            ));
          } else {
            OpenFilex.open(file.path);
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isSelected ? Border.all(color: APP_COLOR.primary2Color, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: isSelected ? APP_COLOR.primary2Color.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSelected ? 15 : 18),
          child: Stack(
            children: [
              Positioned.fill(
                child: Hero(
                  tag: file.path,
                  child: _buildPreview(file),
                ),
              ),

              if (isSelected)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.check_circle, color: APP_COLOR.primary2Color, size: 26),
                  ),
                ),

              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 4, left: 8, right: 0,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (!_isSelectionMode)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                        onSelected: (value) => _handleMenuSelection(value, file),
                        itemBuilder: (context) => [
                          _buildPopupItem("Share", Icons.share_outlined, Colors.blue),
                          _buildPopupItem("Export", Icons.file_download_outlined, Colors.green),
                          const PopupMenuDivider(),
                          _buildPopupItem("Delete", Icons.delete_outline, Colors.red),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String title, IconData icon, Color color) {
    return PopupMenuItem(
      value: title,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value, File file) async {
    if (value == "Export") {
      bool success = await _mediaService.exportFile(file.path, widget.type);
      _showSnackBar(success ? "Saved to Gallery!" : "Export Failed!");
    } else if (value == "Delete") {
      _confirmDelete(file);
    } else if (value == "Share") {
      Share.shareXFiles([XFile(file.path)]);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildPreview(File file) {
    if (widget.type == "Photos") {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
        ),
      );
    }

    if (widget.type == "Videos") {
      return FutureBuilder(
        future: _initializeVideoPreview(file),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
            final controller = snapshot.data as VideoPlayerController;
            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                ),
              ],
            );
          }
          return Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
        },
      );
    }

    IconData icon = Icons.insert_drive_file_rounded;
    Color color = Colors.orange;
    if (widget.type == "Audio") { icon = Icons.audiotrack_rounded; color = Colors.purple; }
    else if (widget.type == "Files") { icon = Icons.description_rounded; color = Colors.blue; }

    return Container(color: color.withOpacity(0.05), child: Center(child: Icon(icon, color: color, size: 40)));
  }

  Future<VideoPlayerController?> _initializeVideoPreview(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      await controller.setVolume(0);
      return controller;
    } catch (e) {
      return null;
    }
  }

  Widget _buildEmptyUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text("No ${widget.type} found", style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _confirmDelete(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete file?"),
        content: const Text("Do you really want to delete this file?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await file.delete();
              _loadVaultFiles();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _viewImage(int index) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ImageViewerPage(imageList: _files, initialIndex: index)));
  }
}