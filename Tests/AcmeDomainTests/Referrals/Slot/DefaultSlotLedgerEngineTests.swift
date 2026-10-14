@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultSlotLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultDefaultSlotLedgerEngine()
        let item = Referrals.newDefaultSlotLedger("code-725", label: "label-735")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
