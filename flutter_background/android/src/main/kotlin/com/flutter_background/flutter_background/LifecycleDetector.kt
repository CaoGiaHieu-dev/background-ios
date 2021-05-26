package com.flutter_background.flutter_background


import android.app.Activity
import android.app.Application
import android.os.Bundle
import androidx.annotation.NonNull
object LifecycleDetector {

    val activityLifecycleCallbacks: Application.ActivityLifecycleCallbacks =
        ActivityLifecycleCallbacks()

    var listener: Listener? = null

    var isActivityRunning = false
        private set

    interface Listener {

        fun onFlutterActivityCreated()

        fun onFlutterActivityDestroyed()

    }

    private class ActivityLifecycleCallbacks : Application.ActivityLifecycleCallbacks {
        override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
            isActivityRunning = true
            listener?.onFlutterActivityCreated()
        }
        override fun onActivityDestroyed(activity: Activity) {
            isActivityRunning = false
            listener?.onFlutterActivityDestroyed()
        }

        override fun onActivityStarted(activity: Activity) {}

        override fun onActivityStopped(activity: Activity) {}

        override fun onActivityResumed(activity: Activity) {}

        override fun onActivityPaused(activity: Activity) {}

        override fun onActivitySaveInstanceState(@NonNull activity: Activity, @NonNull outState: Bundle) {}
    }

}