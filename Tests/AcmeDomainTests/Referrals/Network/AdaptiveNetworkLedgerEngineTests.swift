@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveNetworkLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultAdaptiveNetworkLedgerEngine()
        let item = Referrals.newAdaptiveNetworkLedger("code-787", name: "name-611")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
