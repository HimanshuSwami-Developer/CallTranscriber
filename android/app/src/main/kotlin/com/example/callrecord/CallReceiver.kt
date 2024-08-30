package com.example.callrecord

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log

class CallReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
            val phoneNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER) ?: ""

            when (state) {
                TelephonyManager.EXTRA_STATE_RINGING -> {
                    Log.d("CallReceiver", "Phone is ringing, number: $phoneNumber")
                }
                TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                    Log.d("CallReceiver", "Call answered, number: $phoneNumber")
                    val serviceIntent = Intent(context, CallRecordingService::class.java).apply {
                        putExtra("PHONE_NUMBER", phoneNumber)
                    }
                    context?.startService(serviceIntent)
                }
                TelephonyManager.EXTRA_STATE_IDLE -> {
                    Log.d("CallReceiver", "Call ended")
                    val serviceIntent = Intent(context, CallRecordingService::class.java)
                    context?.stopService(serviceIntent)
                }
            }
        }
    }
}
