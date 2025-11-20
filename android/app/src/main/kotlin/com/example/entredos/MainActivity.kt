package com.example.entredos

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.content.ContentValues
import android.os.Environment
import android.util.Log
import java.io.FileInputStream
import java.io.IOException
import java.io.File
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "entredos/scan")
            .setMethodCallHandler { call, result ->
                if (call.method == "scanFile") {
                    val path = call.argument<String>("path")
                    val file = File(path)
                    val uri = Uri.fromFile(file)
                    sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, uri))
                    result.success(null)
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "entredos/saveToDownloads")
            .setMethodCallHandler { call, result ->
                if (call.method == "saveFileToDownloads") {
                    val sourcePath = call.argument<String>("sourcePath")
                    val fileName = call.argument<String>("fileName")
                    val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                    if (sourcePath == null || fileName == null) {
                        result.error("invalid_args", "sourcePath or fileName missing", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val srcFile = File(sourcePath)
                        if (!srcFile.exists()) {
                            result.error("not_found", "Source file not found", null)
                            return@setMethodCallHandler
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val values = ContentValues().apply {
                                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/EntreDos")
                                put(MediaStore.Downloads.IS_PENDING, 1)
                            }

                            val resolver = applicationContext.contentResolver
                            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                            if (uri == null) {
                                result.error("insert_failed", "Unable to create MediaStore entry", null)
                                return@setMethodCallHandler
                            }

                            var out: java.io.OutputStream? = null
                            var `in`: FileInputStream? = null
                            try {
                                `in` = FileInputStream(srcFile)
                                out = resolver.openOutputStream(uri)
                                if (out == null) throw IOException("Unable to open output stream")
                                val buffer = ByteArray(8 * 1024)
                                var read: Int
                                while (`in`.read(buffer).also { read = it } != -1) {
                                    out.write(buffer, 0, read)
                                }
                                out.flush()
                            } finally {
                                try { `in`?.close() } catch (_: Exception) {}
                                try { out?.close() } catch (_: Exception) {}
                            }

                            // mark not pending
                            values.clear()
                            values.put(MediaStore.Downloads.IS_PENDING, 0)
                            resolver.update(uri, values, null, null)

                            result.success(null)
                            return@setMethodCallHandler
                        } else {
                            // Fallback for older devices: copy to public Downloads directory
                            val downloads = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                            val target = File(downloads, fileName)
                            srcFile.copyTo(target, overwrite = true)
                            // notify media scanner
                            val uri = Uri.fromFile(target)
                            sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, uri))
                            result.success(null)
                            return@setMethodCallHandler
                        }
                    } catch (e: Exception) {
                        Log.e("MainActivity", "saveFileToDownloads failed", e)
                        result.error("exception", e.message, null)
                        return@setMethodCallHandler
                    }
                }
            }
    }
}