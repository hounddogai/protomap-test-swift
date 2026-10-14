@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalSlotAdjustmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultGlobalSlotAdjustmentEngine()
        let item = Referrals.newGlobalSlotAdjustment("code-586", label: "label-624")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
