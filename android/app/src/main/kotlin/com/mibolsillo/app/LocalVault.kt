package com.mibolsillo.app

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import java.security.SecureRandom
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey

/** Separate Keystore aliases let queue deletion destroy its own encryption key. */
internal object LocalVault {
    private const val DB_ALIAS = "mi_bolsillo_database_v1"
    private const val QUEUE_ALIAS = "mi_bolsillo_queue_v1"
    private fun store() = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    private fun key(alias: String, create: Boolean): SecretKey {
        val store = store()
        (store.getKey(alias, null) as? SecretKey)?.let { return it }
        check(create) { "Missing local key" }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
            init(KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256).setRandomizedEncryptionRequired(true).build())
        }.generateKey()
    }
    private fun seal(alias: String, purpose: String, value: ByteArray): String {
        return "v1:" + Base64.encodeToString(SealedPayload.encrypt(key(alias, true), purpose, value), Base64.NO_WRAP)
    }
    private fun open(alias: String, purpose: String, value: String): ByteArray {
        check(value.startsWith("v1:"))
        val packed = Base64.decode(value.substring(3), Base64.NO_WRAP)
        return SealedPayload.decrypt(key(alias, false), purpose, packed)
    }
    @Synchronized fun databaseKey(context: Context): String {
        val prefs = context.getSharedPreferences("financial_keys", Context.MODE_PRIVATE)
        val wrapped = prefs.getString("database", null)
        val raw = if (wrapped != null) open(DB_ALIAS, "database", wrapped) else {
            val bytes = ByteArray(32).also { SecureRandom().nextBytes(it) }
            check(prefs.edit().putString("database", seal(DB_ALIAS, "database", bytes)).commit())
            bytes
        }
        return try { raw.joinToString("") { "%02x".format(it) } } finally { raw.fill(0) }
    }
    @Synchronized fun encryptQueue(id: String, value: String) = seal(QUEUE_ALIAS, id, value.toByteArray(Charsets.UTF_8))
    @Synchronized fun decryptQueue(id: String, value: String) = String(open(QUEUE_ALIAS, id, value), Charsets.UTF_8)
    @Synchronized fun forgetQueueKey() { store().deleteEntry(QUEUE_ALIAS) }
}
