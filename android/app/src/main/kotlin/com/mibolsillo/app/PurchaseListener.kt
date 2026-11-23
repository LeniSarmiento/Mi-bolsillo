package com.mibolsillo.app

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONObject

internal object DetectionQueue {
    private fun prefs(c: Context) = c.getSharedPreferences("purchase_queue", Context.MODE_PRIVATE)
    var onArrival: (() -> Unit)? = null

    fun optedIn(c: Context) = prefs(c).getBoolean("enabled", false)
    fun enable(c: Context, value: Boolean) { check(prefs(c).edit().putBoolean("enabled", value).commit()) }
    fun erase(c: Context) { check(prefs(c).edit().clear().commit()) }

    fun add(c: Context, p: Purchase) {
        val store = prefs(c)
        if (!optedIn(c) || store.contains(p.id) || store.all.size >= 513) return
        val data = JSONObject().put("id", p.id).put("merchant", p.merchant).put("amount", p.amount)
            .put("date", p.date).put("app", p.app)
        if (store.edit().putString(p.id, data.toString()).commit()) onArrival?.invoke()
    }

    fun peek(c: Context) = prefs(c).all.values.filterIsInstance<String>().map {
        val data = JSONObject(it)
        mapOf("id" to data.getString("id"), "merchant" to data.getString("merchant"),
            "amount" to data.getLong("amount"), "date" to data.getLong("date"), "app" to data.getString("app"))
    }

    fun ack(c: Context, keys: List<String>) {
        val edit = prefs(c).edit()
        keys.filter { it.matches(Regex("[a-f0-9]{64}")) }.forEach { edit.remove(it) }
        check(edit.commit())
    }
}

class PurchaseListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        if (!DetectionQueue.optedIn(this) || sbn.packageName !in PurchaseParser.apps) return
        val notice = sbn.notification
        if ((notice.flags and Notification.FLAG_GROUP_SUMMARY) != 0) return
        val extras = notice.extras
        val body = extras.getCharSequence(Notification.EXTRA_BIG_TEXT) ?: extras.getCharSequence(Notification.EXTRA_TEXT)
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)
        val text = listOfNotNull(title, body).joinToString(" ").take(1200)
        val posted = notice.`when`.takeIf { it > 0 } ?: sbn.postTime
        PurchaseParser.parse(sbn.packageName, sbn.key, posted, text)?.let { DetectionQueue.add(this, it) }
    }
}
