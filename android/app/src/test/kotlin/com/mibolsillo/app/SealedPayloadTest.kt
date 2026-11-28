package com.mibolsillo.app

import org.junit.Assert.*
import org.junit.Test
import javax.crypto.AEADBadTagException
import javax.crypto.KeyGenerator

class SealedPayloadTest {
    private fun key() = KeyGenerator.getInstance("AES").apply { init(256) }.generateKey()
    private val plain = "SYNTHETIC_NOTICE_ONLY".toByteArray()

    @Test fun encryptsAndUsesFreshNonces() {
        val key = key()
        val first = SealedPayload.encrypt(key, "notice-1", plain)
        val second = SealedPayload.encrypt(key, "notice-1", plain)
        assertFalse(first.contentEquals(second))
        assertFalse(String(first, Charsets.ISO_8859_1).contains("SYNTHETIC_NOTICE_ONLY"))
        assertArrayEquals(plain, SealedPayload.decrypt(key, "notice-1", first))
    }

    @Test fun rejectsWrongKeyAndRecordSubstitution() {
        val key = key()
        val packed = SealedPayload.encrypt(key, "notice-1", plain)
        assertThrows(AEADBadTagException::class.java) { SealedPayload.decrypt(key(), "notice-1", packed) }
        assertThrows(AEADBadTagException::class.java) { SealedPayload.decrypt(key, "notice-2", packed) }
    }

    @Test fun rejectsAlteredNonceCiphertextTagAndTruncation() {
        val key = key()
        val packed = SealedPayload.encrypt(key, "notice-1", plain)
        for (position in listOf(0, 12, packed.lastIndex)) {
            val changed = packed.copyOf()
            changed[position] = (changed[position].toInt() xor 1).toByte()
            assertThrows(AEADBadTagException::class.java) { SealedPayload.decrypt(key, "notice-1", changed) }
        }
        assertThrows(IllegalArgumentException::class.java) { SealedPayload.decrypt(key, "notice-1", packed.copyOf(20)) }
    }
}
