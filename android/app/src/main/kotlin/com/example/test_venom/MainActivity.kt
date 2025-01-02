package com.example.test_venom

import android.Manifest
import android.content.pm.PackageManager
import android.database.Cursor
import android.provider.CallLog
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.content.ContentResolver
import android.content.Context
import android.os.Bundle
import android.provider.ContactsContract
import android.provider.Telephony
import android.widget.Toast
import androidx.core.app.ActivityCompat.requestPermissions
import android.os.Environment
import android.util.Log
import android.provider.MediaStore
import java.io.File

class MainActivity: FlutterActivity() {

    private val CHANNEL = "com.example.test_venom/call_logs"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getCallLogs") {
                while (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CALL_LOG) != PackageManager.PERMISSION_GRANTED) {
                    ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.READ_CALL_LOG), 1)
                } 
                result.success(getCallLogs())
                
            } else if (call.method == "makeCall") {
                val phoneNumber = call.argument<String>("phoneNumber") // Get the phone number from the Flutter side
                if (phoneNumber != null && phoneNumber.isNotEmpty()) {
                    // Check for CALL_PHONE permission
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CALL_PHONE), 1)
                        result.error("PERMISSION_DENIED", "CALL_PHONE permission not granted", null)
                    } else {
                        // Make the call
                        val callIntent = Intent(Intent.ACTION_CALL).apply {
                            data = Uri.parse("tel:$phoneNumber")
                        }
                        try {
                            startActivity(callIntent)
                            result.success("Calling $phoneNumber")
                        } catch (e: Exception) {
                            result.error("CALL_FAILED", "Failed to make the call: ${e.message}", null)
                        }
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Phone number is null or empty", null)
                }
            }
            else if (call.method == "getContacts") {
                val contacts = mutableListOf<Map<String, String>>()
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED) {
                    val cursor = contentResolver.query(
                        ContactsContract.Contacts.CONTENT_URI, 
                        null, null, null, null
                    )
                    
                    cursor?.use {
                        while (it.moveToNext()) {
                            val contactId = it.getString(it.getColumnIndex(ContactsContract.Contacts._ID))
                            val contactName = it.getString(it.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME))
                            val phoneCursor = contentResolver.query(
                                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                                null,
                                ContactsContract.CommonDataKinds.Phone.CONTACT_ID + " = ?",
                                arrayOf(contactId),
                                null
                            )
                            
                            phoneCursor?.use { phones ->
                                while (phones.moveToNext()) {
                                    val phoneNumber = phones.getString(phones.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER))
                                    contacts.add(mapOf("name" to contactName, "phone" to phoneNumber))
                                }
                            }
                        }
                    }
                    result.success(contacts)
                } else {
                    ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.READ_CONTACTS), 1)
                    result.error("PERMISSION_DENIED", "READ_CONTACTS permission not granted", null)
                }
            }
            else if (call.method == "getMessages") {
                val phoneNumber = call.argument<String>("phoneNumber")
                val messages = mutableListOf<Map<String, String>>()
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED) {
                    val cursor = contentResolver.query(
                        Telephony.Sms.CONTENT_URI,
                        null, "${Telephony.Sms.ADDRESS} = ?",
                        arrayOf(phoneNumber), "date DESC"
                    )
                    
                    cursor?.use {
                        while (it.moveToNext()) {
                            val address = it.getString(it.getColumnIndexOrThrow(Telephony.Sms.ADDRESS))
                            val body = it.getString(it.getColumnIndexOrThrow(Telephony.Sms.BODY))
                            messages.add(mapOf("address" to address, "body" to body))
                        }
                    }
                    result.success(messages)
                } else {
                    ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.READ_SMS), 1)
                    result.error("PERMISSION_DENIED", "READ_SMS permission not granted", null)
                }
            }
            else if (call.method == "getGalleryImages") {
                val images = mutableListOf<String>()
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED) {
                    val cursor = contentResolver.query(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                        arrayOf(MediaStore.Images.Media.DATA),
                        null,
                        null,
                        null
                    )
                    
                    cursor?.use {
                        while (it.moveToNext()) {
                            val imagePath = it.getString(it.getColumnIndex(MediaStore.Images.Media.DATA))
                            images.add(imagePath)
                        }
                    }
                    result.success(images)
                } else {
                    ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE), 1)
                    result.error("PERMISSION_DENIED", "READ_EXTERNAL_STORAGE permission not granted", null)
                }
            }
            else if (call.method == "getFiles") {
                val files = mutableListOf<String>()
                val directory = File(Environment.getExternalStorageDirectory().path)
                if (directory.exists() && directory.isDirectory) {
                    directory.listFiles()?.forEach { file ->
                        if (file.isFile) {
                            files.add(file.absolutePath)
                        }
                    }
                    result.success(files)
                } else {
                    result.error("FILE_NOT_FOUND", "Directory not found or accessible", null)
                }
            }
            else if (call.method == "openCamera") {
                val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
                try {
                    startActivityForResult(intent, 1)
                    result.success("Camera opened")
                } catch (e: Exception) {
                    ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CAMERA), 1)
                    result.error("PERMISSION_DENIED", "CAMERA permission not granted", null)
                }
            }
            else if (call.method == "getWhatsappChats") {
                val phoneNumber = call.argument<String>("phoneNumber")
                val message = call.argument<String>("message")
                
                if (phoneNumber != null && message != null) {
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        data = Uri.parse("https://wa.me/$phoneNumber?text=$message")
                        setPackage("com.whatsapp")
                    }
                    try {
                        startActivity(intent)
                        result.success("WhatsApp message sent")
                    } catch (e: Exception) {
                        result.error("WHATSAPP_FAILED", "Failed to send message: ${e.message}", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Phone number or message is null", null)
                }
            }
                                                                               
             else {
                result.success(listOf("No Implementation"))
            }
        }
    }

    private fun getCallLogs(): List<Map<String, Any>> {
        val callLogs = mutableListOf<Map<String, Any>>()
        val cursor: Cursor? = contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            null,
            null,
            null,
            null
        )
    
        cursor?.use {
            val numberColumn = it.getColumnIndex(CallLog.Calls.NUMBER)
            val typeColumn = it.getColumnIndex(CallLog.Calls.TYPE)
            val dateColumn = it.getColumnIndex(CallLog.Calls.DATE)
            val durationColumn = it.getColumnIndex(CallLog.Calls.DURATION)
            val nameColumn = it.getColumnIndex(CallLog.Calls.CACHED_NAME)
            val numberTypeColumn = it.getColumnIndex(CallLog.Calls.CACHED_NUMBER_TYPE)
            val photoUriColumn = it.getColumnIndex(CallLog.Calls.CACHED_PHOTO_URI)
            val locationColumn = it.getColumnIndex(CallLog.Calls.GEOCODED_LOCATION)
            val newColumn = it.getColumnIndex(CallLog.Calls.NEW)
            val accountIdColumn = it.getColumnIndex(CallLog.Calls.PHONE_ACCOUNT_ID)
            val accountComponentColumn = it.getColumnIndex(CallLog.Calls.PHONE_ACCOUNT_COMPONENT_NAME)
    
            var recordCount = 0 // Track the number of records processed
            println("Test 0")
    
            while (it.moveToNext()) {
                if (recordCount >= 10) {
                    break // Limit to 10 records
                }
    
                val number = it.getString(numberColumn) ?: "Unknown" // Handle null values
                val type = it.getString(typeColumn) ?: "Unknown"
                val date = it.getString(dateColumn) ?: "Unknown"
                val duration = it.getString(durationColumn) ?: "0"
                val name = it.getString(nameColumn) ?: "Unknown"
                val numberType = it.getString(numberTypeColumn) ?: "Unknown"
                val photoUri = it.getString(photoUriColumn) ?: "Unknown"
                val location = it.getString(locationColumn) ?: "Unknown"
                val isNew = it.getInt(newColumn) == 1 // Convert to Boolean
                val accountId = it.getString(accountIdColumn) ?: "Unknown"
                val accountComponent = it.getString(accountComponentColumn) ?: "Unknown"
    
                // Create a map for the current call log
                val callLog = mapOf(
                    "number" to number,
                    "type" to type,
                    "date" to date,
                    "duration" to duration,
                    "name" to name,
                    "numberType" to numberType,
                    "photoUri" to photoUri,
                    "location" to location,
                    "isNew" to isNew,
                    "accountId" to accountId,
                    "accountComponent" to accountComponent
                )
    
                // Add the call log to the list
                callLogs.add(callLog)
                recordCount++
                println("Test one")
            }
        }
    
        return callLogs
    }
    

}
