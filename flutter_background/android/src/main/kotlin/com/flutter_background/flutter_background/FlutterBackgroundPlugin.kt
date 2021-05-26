package com.flutter_background.flutter_background

import androidx.annotation.NonNull
import androidx.annotation.Keep
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.content.Context
import android.util.Log;
import android.os.Bundle
import android.app.Application
import android.content.Intent
import android.os.Build;

class FlutterBackgroundPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  private lateinit var methodChannel : MethodChannel
  private lateinit var eventChannel:EventChannel
  private val ws = WS()
  private var applicationContext: Context? =null

  // private val background= BackgroundService()


  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    this.applicationContext = flutterPluginBinding.applicationContext

    BackgroundNotification.createNotificationChannels(flutterPluginBinding.applicationContext)

    methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "sbapp/MethodBackgroundHandler")

    eventChannel= EventChannel(flutterPluginBinding.binaryMessenger, "sbapp/EventBackgroundHandler")

    methodChannel.setMethodCallHandler(this)

    eventChannel.setStreamHandler(this)
  }
  override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink?) {
    ws.listenEvent(arguments as String,eventSink)
  }
  override fun onCancel(arguments: Any?){

  }
  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "createNotificationChannel") {
      val argData = call.arguments as java.util.HashMap<String, String>
      Notification().createNotificationChannel(applicationContext!!,argData)
    } else if( call.method == "connectServer") {
      val arguments = call.arguments as java.util.HashMap<String?, String?>
      val host = arguments["host"] as String
      val argData = arguments["data"] as String
      ws.connect(host,argData)
      result.success("success")
    } else if ( call.method =="backgroundTask"){

      val callbackRawHandle = call.arguments as Long
      BackgroundService.startService(applicationContext!!, "createNotificationChannel")
      result.success(null)
    } else if ( call.method =="app_retain"){
      FlutterActivity().moveTaskToBack(true)
      result.success(null)
    }else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }
}
