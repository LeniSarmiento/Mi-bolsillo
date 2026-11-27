package com.mibolsillo.app

import java.security.MessageDigest
import java.text.Normalizer
import java.util.Locale

data class Purchase(val id: String, val merchant: String, val amount: Long, val date: Long, val app: String, val legacyId: String? = null)

object PurchaseParser {
    val apps = mapOf(
        "co.com.bancolombia.personas.superapp" to "Bancolombia",
        "com.nequi.MobileApp" to "Nequi",
        "com.davivienda.daviplataapp" to "DaviPlata"
    )
    private val purchase = Regex("""\b(compraste|pagaste|compra aprobada|pago exitoso)\b""", RegexOption.IGNORE_CASE)
    private val ignore = Regex("""rechaz|declinad|cancelad|revers|devolu|intento|código|codigo|saldo disponible para|si compraste|no (?:compraste|pagaste)|\b(?:USD|EUR)\b""", RegexOption.IGNORE_CASE)
    private val money = Regex("""(?:COP\s*\$?|\$)\s*(\d[\d.,]*)""", RegexOption.IGNORE_CASE)
    private val pesos = Regex("""(?:\d{1,3}(?:\.\d{3})+|\d+)(?:,00)?""")
    private val merchantName = Regex("""\ben\s+([\p{L}\d][\p{L}\d &'_-]{1,58}?)(?=\s+(?:con|por|el|desde|a las|saldo)\b|[.,;!]|$)""", RegexOption.IGNORE_CASE)
    private val recipientName = Regex("""\b(?:en|a)\s+([\p{L}\d][\p{L}\d &'_-]{1,58}?)(?=\s+(?:con|por|el|desde|a las|saldo)\b|[.,;!]|$)""", RegexOption.IGNORE_CASE)

    private fun identity(pkg: String, key: String, date: Long, amount: Long, merchant: String): String {
        val fingerprint = listOf(pkg, key, date, amount, merchant).joinToString("|").toByteArray(Charsets.UTF_8)
        return MessageDigest.getInstance("SHA-256").digest(fingerprint).joinToString("") { "%02x".format(it) }
    }

    fun parse(pkg: String, key: String, date: Long, text: String): Purchase? {
        val app = apps[pkg] ?: return null
        if (!purchase.containsMatchIn(text) || ignore.containsMatchIn(text)) return null
        val amounts = money.findAll(text).toList()
        if (amounts.size != 1) return null
        val token = amounts.single().groupValues[1].trimEnd('.', ',')
        if (!pesos.matches(token)) return null
        val amount = token.removeSuffix(",00").replace(".", "").toLongOrNull() ?: return null
        if (amount !in 1..9007199254740991L) return null
        val legacyMerchant = merchantName.find(text)?.groupValues?.get(1)?.trim() ?: "Comercio por identificar"
        val normalizedText = Normalizer.normalize(text, Normalizer.Form.NFKC).replace(Regex("\\s+"), " ")
        val normalizedAmount = money.find(normalizedText) ?: return null
        val afterAmount = normalizedText.substring(normalizedAmount.range.last + 1)
        val merchant = recipientName.find(afterAmount)?.groupValues?.get(1)?.trim() ?: "Comercio por identificar"
        val normalizedMerchant = merchant.uppercase(Locale.ROOT)
        val id = identity(pkg, key, date, amount, normalizedMerchant)
        return Purchase(id, merchant, amount, date, app, identity(pkg, key, date, amount, legacyMerchant))
    }
}
