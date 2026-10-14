import AcmePlatform
import Foundation
import Testing

@Suite struct KitMoneyTests {
    @Test func splitsWithoutLosingACent() throws {
        let total = Kit.Money.of(1001, currency: "usd")
        let shares = total.split(3)
        #expect(shares.count == 3)
        #expect(shares[0].units == 334)
        #expect(total.currency == "USD")
    }

    @Test func refusesToMixCurrencies() throws {
        let euros = Kit.Money.of(100, currency: "EUR")
        #expect(throws: (any Error).self) { try euros.plus(Kit.Money.of(5, currency: "USD")) }
    }
}
