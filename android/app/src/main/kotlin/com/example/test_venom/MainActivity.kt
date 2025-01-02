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
