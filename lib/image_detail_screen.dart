// ignore_for_file: library_private_types_in_public_api, unused_local_variable, prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class ImageDetailScreen extends StatefulWidget {
  final List<Map<String, String>> galleryItems;
  final int initialIndex;

  const ImageDetailScreen(
      {required this.galleryItems, required this.initialIndex});

  @override
  _ImageDetailScreenState createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  static const platform = MethodChannel('com.example.gallery_app/gallery');
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  Future<void> _editImage(String path) async {
    try {
      if (await _requestPermission(Permission.storage)) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: path,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              minimumAspectRatio: 1.0,
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            widget.galleryItems[currentIndex]['path'] = croppedFile.path;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Storage permission is required to edit images.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image cropping failed. Please try again.')),
      );
    }
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      final result = await permission.request();
      return result == PermissionStatus.granted;
    }
  }

  Future<void> _deleteImage(String path, bool permanent) async {
    try {
      if (permanent) {
        final result = await platform.invokeMethod('deleteImage', path);
        setState(() {
          widget.galleryItems.removeAt(currentIndex);
          if (widget.galleryItems.isNotEmpty) {
            currentIndex = currentIndex % widget.galleryItems.length;
          } else {
            Navigator.pop(context);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image deleted permanently.')),
        );
      } else {
        final trashDir = Directory('/path/to/trash');
        if (!await trashDir.exists()) {
          await trashDir.create(recursive: true);
        }
        final file = File(path);
        if (await file.exists()) {
          await file.rename('${trashDir.path}/${file.uri.pathSegments.last}');
          setState(() {
            widget.galleryItems.removeAt(currentIndex);
            if (widget.galleryItems.isNotEmpty) {
              currentIndex = currentIndex % widget.galleryItems.length;
            } else {
              Navigator.pop(context);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image moved to trash.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image delete failed: $e. Please try again.')),
      );
    }
  }

  void _showImageDetails(BuildContext context, Map<String, String> item) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: [
            ListTile(
              title: Text("Name"),
              subtitle: Text(item['name']!),
            ),
            ListTile(
              title: Text("Date Added"),
              subtitle: Text(item['date']!),
            ),
            ListTile(
              title: Text("Path"),
              subtitle: Text(item['path']!),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Detail'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () =>
                _editImage(widget.galleryItems[currentIndex]['path']!),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () =>
                _deleteImage(widget.galleryItems[currentIndex]['path']!, false),
          ),
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () =>
                _showImageDetails(context, widget.galleryItems[currentIndex]),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete_permanently') {
                _deleteImage(widget.galleryItems[currentIndex]['path']!, true);
              } else if (value == 'move_to_trash') {
                _deleteImage(widget.galleryItems[currentIndex]['path']!, false);
              }
            },
            itemBuilder: (BuildContext context) {
              return {'delete_permanently', 'move_to_trash'}
                  .map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice == 'delete_permanently'
                      ? 'Delete Permanently'
                      : 'Move to Trash'),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: PhotoViewGallery.builder(
        itemCount: widget.galleryItems.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: FileImage(File(widget.galleryItems[index]['path']!)),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        pageController: PageController(initialPage: widget.initialIndex),
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}
