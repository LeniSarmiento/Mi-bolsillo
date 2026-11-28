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
    @Synchronized fun erase(c: Context) {
        check(prefs(c).edit().clear().commit())
        LocalVault.forgetQueueKey()
    }

    @Synchronized fun add(c: Context, p: Purchase) {
        val store = prefs(c)
        if (!optedIn(c) || store.contains(p.id) || store.all.size >= 513) return
        val data = JSONObject().put("id", p.id).put("merchant", p.merchant).put("amount", p.amount)
            .put("date", p.date).put("app", p.app)
        p.legacyId?.let { data.put("legacyId", it) }
        if (store.edit().putString(p.id, LocalVault.encryptQueue(p.id, data.toString())).commit()) onArrival?.invoke()
    }

    @Synchronized fun peek(c: Context): List<Map<String, Any>> {
      val store = prefs(c)
      // Upgrade legacy plaintext entries atomically before returning their data.
      val legacy = store.all.filterValues { it is String && !it.startsWith("v1:") }
      if (legacy.isNotEmpty()) {
          val edit = store.edit()
          legacy.forEach { (id, value) -> edit.putString(id, LocalVault.encryptQueue(id, value as String)) }
          check(edit.commit())
      }
      return store.all.filterValues { it is String }.map { (id, value) ->
        val data = JSONObject(LocalVault.decryptQueue(id, value as String))
        mapOf("id" to data.getString("id"), "merchant" to data.getString("merchant"),
            "amount" to data.getLong("amount"), "date" to data.getLong("date"), "app" to data.getString("app"),
            "legacyId" to data.optString("legacyId", ""))
      }
    }

    @Synchronized fun ack(c: Context, keys: List<String>) {
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
        try {
            PurchaseParser.parse(sbn.packageName, sbn.key, posted, text)?.let { DetectionQueue.add(this, it) }
        } catch (_: Exception) {
            // Keystore can be unavailable before unlock. Never fall back to plaintext or log content.
        }
    }
}
