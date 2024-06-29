// ignore_for_file: prefer_const_constructors, avoid_print, use_key_in_widget_constructors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'permission_service.dart';
import 'image_detail_screen.dart';

class GalleryScreen extends StatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const platform = MethodChannel('com.example.gallery_app/gallery');
  List<Map<String, String>> _galleryItems = [];
  List<String> _albums = [];
  String? _selectedAlbum;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadGallery(String? album) async {
    if (await PermissionService.requestStoragePermission()) {
      try {
        final List<dynamic> result =
            await platform.invokeMethod('getGallery', album);
        setState(() {
          _galleryItems = List<Map<String, String>>.from(
              result.map((item) => Map<String, String>.from(item)));
        });
      } on PlatformException catch (e) {
        print("Failed to load gallery: '${e.message}'.");
      }
    } else {
      print("Storage permission denied");
    }
  }

  Future<void> _loadAlbums() async {
    if (await PermissionService.requestStoragePermission()) {
      try {
        final List<dynamic> result = await platform.invokeMethod('getAlbums');
        setState(() {
          _albums = List<String>.from(result);
        });
        if (_albums.isNotEmpty) {
          _selectedAlbum = _albums.first;
          await _loadGallery(_selectedAlbum);
        }
      } on PlatformException catch (e) {
        print("Failed to load albums: '${e.message}'.");
      }
    } else {
      print("Storage permission denied");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButton<String>(
          value: _selectedAlbum,
          onChanged: (String? newValue) {
            setState(() {
              _selectedAlbum = newValue;
              _loadGallery(_selectedAlbum);
            });
          },
          items: _albums.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        Expanded(
          child: _galleryItems.isEmpty
              ? Center(child: CircularProgressIndicator())
              : GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3),
                  itemCount: _galleryItems.length,
                  itemBuilder: (context, index) {
                    final item = _galleryItems[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageDetailScreen(
                              galleryItems: _galleryItems,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: item['type'] == 'image'
                          ? Image.file(File(item['path']!), fit: BoxFit.cover)
                          : VideoThumbnail(item['path']!),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class VideoThumbnail extends StatefulWidget {
  final String path;

  const VideoThumbnail(this.path);

  @override
  _VideoThumbnailState createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Stack(
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              Center(
                child: IconButton(
                  icon: Icon(Icons.play_circle_fill,
                      color: Colors.white, size: 50),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VideoPlayerScreen(controller: _controller),
                      ),
                    );
                  },
                ),
              ),
            ],
          )
        : Center(child: CircularProgressIndicator());
  }
}

class VideoPlayerScreen extends StatelessWidget {
  final VideoPlayerController controller;

  const VideoPlayerScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.value.isPlaying ? controller.pause() : controller.play();
        },
        child:
            Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}
