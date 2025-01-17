package com.example.callrecord

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import android.util.Log
import java.io.IOException
import java.util.Date
import java.util.Locale

import java.text.SimpleDateFormat

class CallRecordingService : Service() {

    private var recorder: MediaRecorder? = null
    private var output: String = ""
     private var phoneNumber: String = ""

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
           phoneNumber = intent?.getStringExtra("PHONE_NUMBER") ?: ""
        startRecording()
        return START_STICKY
    }

  private fun startRecording() {
    try {
         val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
            val sanitizedPhoneNumber = phoneNumber.replace(Regex("[^\\d]"), "")
            val fileName = "call_recording_${sanitizedPhoneNumber}_$timestamp.mp3"
            output = "${externalCacheDir?.absolutePath}/$fileName"
           recorder = MediaRecorder().apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setOutputFile(output)
            Log.d("CallRecordingService", "Preparing MediaRecorder")
            prepare()
            Log.d("CallRecordingService", "Starting MediaRecorder")
            start()
        }
    } catch (e: IllegalStateException) {
        Log.e("CallRecordingService", "IllegalStateException: ${e.message}")
        e.printStackTrace()
    } catch (e: IOException) {
        Log.e("CallRecordingService", "IOException: ${e.message}")
        e.printStackTrace()
    }
}

    private fun stopRecording() {
        try {
            recorder?.apply {
                stop()
                release()
            }
        } catch (e: RuntimeException) {
            e.printStackTrace()
        } finally {
            recorder = null
        }
    }

    override fun onDestroy() {
        stopRecording()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
