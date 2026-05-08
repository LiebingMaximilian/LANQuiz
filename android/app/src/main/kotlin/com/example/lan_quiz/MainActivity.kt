package com.example.lan_quiz

import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun onResume() {
        super.onResume()
        val wifiManager = applicationContext.getSystemService(WIFI_SERVICE) as WifiManager
        multicastLock = wifiManager.createMulticastLock("lan_quiz_lock")
        multicastLock?.setReferenceCounted(true)
        multicastLock?.acquire()
    }

    override fun onPause() {
        super.onPause()
        multicastLock?.release()
    }
}