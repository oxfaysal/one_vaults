import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // কীবোর্ড ইভেন্টের জন্য এটি লাগবে
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class ImageViewerPage extends StatefulWidget {
  final List<File> imageList;
  final int initialIndex;

  const ImageViewerPage({
    super.key,
    required this.imageList,
    required this.initialIndex,
  });

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showDetails = false;
  final FocusNode _focusNode = FocusNode(); // কীবোর্ড লিসেনারের জন্য

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // কীবোর্ড দিয়ে ছবি পরিবর্তনের লজিক
  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _nextImage();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _prevImage();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.pop(context); // এস্কেপ টিপলে ক্লোজ হবে
      }
    }
  }

  void _nextImage() {
    if (_currentIndex < widget.imageList.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  String getFileSize(File file) {
    try {
      int bytes = file.lengthSync();
      if (bytes < 1024) return "$bytes B";
      if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
      return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    } catch (e) {
      return "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    // কীবোর্ড লিসেনারে অটো ফোকাস করার জন্য
    FocusScope.of(context).requestFocus(_focusNode);

    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: _handleKeyPress,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text("${_currentIndex + 1} / ${widget.imageList.length}",
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(_showDetails ? Icons.info : Icons.info_outline),
              onPressed: () => setState(() => _showDetails = !_showDetails),
            ),
          ],
        ),
        body: Stack(
          children: [
            // ইমেজ ভিউয়ার
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageList.length,
              physics: const BouncingScrollPhysics(), // স্মুথ স্ক্রলিং
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                File file = widget.imageList[index];
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(
                    tag: file.path,
                    child: Image.file(
                      file,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),

            // ডেস্কটপ নেভিগেশন বাটন (মাউস দিয়ে নেক্সট করার জন্য)
            if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) ...[
              if (_currentIndex > 0)
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white54, size: 40),
                      onPressed: _prevImage,
                    ),
                  ),
                ),
              if (_currentIndex < widget.imageList.length - 1)
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 40),
                      onPressed: _nextImage,
                    ),
                  ),
                ),
            ],

            // ডিটেইলস প্যানেল
            if (_showDetails)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildDetailsPanel(widget.imageList[_currentIndex]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsPanel(File file) {
    // .sav এক্সটেনশন থাকলে রিমুভ করে অরিজিনাল নাম দেখানো
    String fileName = p.basename(file.path).replaceFirst(RegExp(r'vault_\d+_'), '').replaceAll('.sav', '');
    String date = DateFormat('dd MMM yyyy, hh:mm a').format(file.lastModifiedSync());

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(fileName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _detailRow(Icons.calendar_today, "Date", date),
          _detailRow(Icons.sd_storage_outlined, "Size", getFileSize(file)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white60, size: 16),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}