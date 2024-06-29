package com.example.gallery_app

import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.content.UriPermission
import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.gallery_app/gallery"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        flutterEngine?.dartExecutor?.binaryMessenger?.let { binaryMessenger ->
            MethodChannel(binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "getGallery" -> {
                        val album = call.arguments as? String
                        val gallery = getGallery(album)
                        result.success(gallery)
                    }
                    "getAlbums" -> {
                        val albums = getAlbums()
                        result.success(albums)
                    }
                    "deleteImage" -> {
                        val path = call.arguments as String
                        val success = deleteImage(path)
                        if (success) {
                            result.success(null)
                        } else {
                            result.error("DELETE_FAILED", "Failed to delete image", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun getGallery(album: String?): List<Map<String, String>> {
        val gallery = mutableListOf<Map<String, String>>()
        val projection = arrayOf(
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.DISPLAY_NAME,
            MediaStore.Files.FileColumns.DATE_ADDED,
            MediaStore.Files.FileColumns.MEDIA_TYPE,
            MediaStore.Files.FileColumns.DATA,
            MediaStore.Images.Media.BUCKET_DISPLAY_NAME
        )
        val selection = if (album != null) {
            "${MediaStore.Images.Media.BUCKET_DISPLAY_NAME}=? AND (${MediaStore.Files.FileColumns.MEDIA_TYPE}=? OR ${MediaStore.Files.FileColumns.MEDIA_TYPE}=?)"
        } else {
            "${MediaStore.Files.FileColumns.MEDIA_TYPE}=? OR ${MediaStore.Files.FileColumns.MEDIA_TYPE}=?"
        }
        val selectionArgs = if (album != null) {
            arrayOf(
                album,
                MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString(),
                MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString()
            )
        } else {
            arrayOf(
                MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString(),
                MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString()
            )
        }
        val sortOrder = "${MediaStore.Files.FileColumns.DATE_ADDED} DESC"
        val cursor = contentResolver.query(
            MediaStore.Files.getContentUri("external"),
            projection,
            selection,
            selectionArgs,
            sortOrder
        )

        cursor?.use {
            val idColumn = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
            val nameColumn = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
            val dateColumn = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_ADDED)
            val typeColumn = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MEDIA_TYPE)
            val dataColumn = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATA)

            while (it.moveToNext()) {
                val id = it.getLong(idColumn)
                val name = it.getString(nameColumn)
                val date = it.getLong(dateColumn)
                val type = it.getInt(typeColumn)
                val data = it.getString(dataColumn)

                val formattedDate = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date(date * 1000))
                val mediaType = if (type == MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE) "image" else "video"

                gallery.add(mapOf("id" to id.toString(), "name" to name, "date" to formattedDate, "path" to data, "type" to mediaType))
            }
        }
        return gallery
    }

    private fun getAlbums(): List<String> {
        val albums = mutableListOf<String>()
        val projection = arrayOf(
            MediaStore.Images.Media.BUCKET_DISPLAY_NAME
        )
        val cursor = contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            projection,
            null,
            null,
            null
        )

        cursor?.use {
            val bucketColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_DISPLAY_NAME)

            while (it.moveToNext()) {
                val bucket = it.getString(bucketColumn)
                if (!albums.contains(bucket)) {
                    albums.add(bucket)
                }
            }
        }
        return albums
    }

    private fun deleteImage(path: String): Boolean {
        return try {
            val file = File(path)
            val uri = getImageContentUri(file)

            if (uri != null) {
                val rowsDeleted = contentResolver.delete(uri, null, null)
                rowsDeleted > 0
            } else {
                false
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error deleting image", e)
            false
        }
    }

    private fun getImageContentUri(imageFile: File): Uri? {
        val filePath = imageFile.absolutePath
        val cursor = contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            arrayOf(MediaStore.Images.Media._ID),
            MediaStore.Images.Media.DATA + "=? ",
            arrayOf(filePath), null
        )
        return if (cursor != null && cursor.moveToFirst()) {
            val id = cursor.getInt(cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID))
            val baseUri = Uri.parse("content://media/external/images/media")
            Uri.withAppendedPath(baseUri, "" + id)
        } else if (imageFile.exists()) {
            val values = ContentValues()
            values.put(MediaStore.Images.Media.DATA, filePath)
            contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
        } else {
            null
        }
    }
}
