package com.flutter_background.flutter_background

import android.util.Log
import io.socket.client.IO
import io.socket.client.Socket
import io.socket.emitter.Emitter
import org.json.JSONException
import io.flutter.plugin.common.EventChannel
import io.flutter.embedding.android.FlutterActivity
import android.os.Handler
import android.os.Looper

class WS  : FlutterActivity() {
    private var socket: Socket? = null
    private val handler = Handler(Looper.getMainLooper())
    public fun connect(host: String, query: String) {
        try {
            
            val options = IO.Options()
            options.query = query
            options.forceNew = true
            socket = IO.socket(host, options)
            socket!!.connect()
            socket!!.on("connect"){
                args-> Log.e("[SOCKET_IO]","Connect to "+host+" success")
            }
        } catch (e: Exception) {
            Log.e("[SOCKET_IO]:","Error") 
        }

    }
    public fun listenEvent(eventName : String,eventSink:EventChannel.EventSink?) {
        socket!!.on(eventName){
            args -> if(args[0] != null){
                runOnUiThread(
                    object : Runnable {
                        override fun run() {
                            eventSink!!.success(args[0].toString())
                        }
                    }
                )
            }
        }
    }
}