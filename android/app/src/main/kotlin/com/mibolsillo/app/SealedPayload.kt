package com.mibolsillo.app

import javax.crypto.Cipher
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** Standard AES-GCM envelope; the purpose binds ciphertext to its record. */
internal object SealedPayload {
    fun encrypt(key: SecretKey, purpose: String, plaintext: ByteArray): ByteArray {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key)
        cipher.updateAAD(purpose.toByteArray(Charsets.UTF_8))
        check(cipher.iv.size == 12)
        return cipher.iv + cipher.doFinal(plaintext)
    }

    fun decrypt(key: SecretKey, purpose: String, packed: ByteArray): ByteArray {
        require(packed.size > 28)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, packed.copyOfRange(0, 12)))
        cipher.updateAAD(purpose.toByteArray(Charsets.UTF_8))
        return cipher.doFinal(packed.copyOfRange(12, packed.size))
    }
}
