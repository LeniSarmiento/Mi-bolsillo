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
}
