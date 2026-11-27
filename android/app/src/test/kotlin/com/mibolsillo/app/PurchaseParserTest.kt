package com.mibolsillo.app

import org.junit.Assert.*
import org.junit.Test

class PurchaseParserTest {
    private val pkg = "com.nequi.MobileApp"
    private fun parse(text: String) = PurchaseParser.parse(pkg, "key", 123L, text)
    @Test fun pesosAndMerchant() {
        val purchase = parse("Compraste $78.500,00 COP en ÉXITO CALLE 80 con tu tarjeta.")!!
        assertEquals(78500L, purchase.amount)
        assertEquals("ÉXITO CALLE 80", purchase.merchant)
        assertEquals("Nequi", purchase.app)
    }
    @Test fun ambiguousCurrencyAndUnsuccessfulCharges() {
        listOf("Compra rechazada por $7.000", "Compraste USD $5", "Recibiste $500",
            "Compraste $7.000,50", "Compraste $70.00", "Compraste $10.000, saldo $30.000",
            "Código para confirmar: compraste $10.000").forEach { assertNull(parse(it)) }
        assertNull(PurchaseParser.parse("other", "k", 123, "Pagaste $5.000"))
    }
    @Test fun stableNotificationIdentity() {
        val text = "Pagaste $12.000 en Tienda."
        assertEquals(parse(text)!!.id, parse(text)!!.id)
        assertNotEquals(parse(text)!!.id, PurchaseParser.parse(pkg, "another", 123L, text)!!.id)
    }
    @Test fun identityIgnoresMerchantCaseSpacingAndUnicodeComposition() {
        val original = parse("Pagaste $12.000 en ÉXITO CALLE 80.")!!
        listOf("Pagaste $12.000 en éxito calle 80.",
            "Pagaste $12.000 en E\u0301xito   Calle 80.",
            "Pagaste $12.000 en Éxito\u00a0Calle 80.").forEach {
            assertEquals(original.id, parse(it)!!.id)
        }
        assertNotEquals(original.id, PurchaseParser.parse(pkg, "different", 123L, "Pagaste $12.000 en ÉXITO CALLE 80.")!!.id)
        assertNotEquals(original.id, PurchaseParser.parse(pkg, "key", 124L, "Pagaste $12.000 en ÉXITO CALLE 80.")!!.id)
        assertNotEquals(original.id, parse("Pagaste $13.000 en ÉXITO CALLE 80.")!!.id)
    }
    @Test fun paymentRecipientAndLegacyReceiptRemainAvailable() {
        val received = parse("Pagaste $12.000 a TIENDA con tu tarjeta.")!!
        assertEquals("TIENDA", received.merchant)
        val original = parse("Pagaste $12.000 en TIENDA.")!!
        assertEquals(original.id, original.legacyId)
        assertNotNull(received.legacyId)
    }
    @Test fun allAuthorizedApplicationsUseSameConservativeRules() {
        PurchaseParser.apps.forEach { (appPackage, label) ->
            val found = PurchaseParser.parse(appPackage, "key", 123L, "Compra aprobada por COP 12.000,00 en TIENDA.")!!
            assertEquals(label, found.app)
            assertEquals(12000L, found.amount)
            assertNull(PurchaseParser.parse(appPackage, "key", 123L, "Compra aprobada por $12.000 saldo $30.000"))
        }
    }
}
