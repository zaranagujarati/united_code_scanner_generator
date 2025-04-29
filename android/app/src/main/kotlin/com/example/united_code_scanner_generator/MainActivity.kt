package com.unitedtechandsolutions.united_code_scanner_generator

import android.content.ContentValues
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "image_saver"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "saveImageToGallery") {
                val byteArray = call.argument<ByteArray>("bytes")
                val success = saveImageToGallery(byteArray!!)
                result.success(success)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveImageToGallery(imageData: ByteArray): Boolean {
        val filename = "qr_code_${System.currentTimeMillis()}.png"
        val resolver = contentResolver
        val contentValues = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, filename)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/QRCode")
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }

        val imageUri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
        if (imageUri != null) {
            resolver.openOutputStream(imageUri).use { outputStream: OutputStream? ->
                outputStream?.write(imageData)
            }
            contentValues.clear()
            contentValues.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(imageUri, contentValues, null, null)
            return true
        }
        return false
    }
}

