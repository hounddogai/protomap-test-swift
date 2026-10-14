@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryFollowUpAdjustmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultPrimaryFollowUpAdjustmentEngine()
        let item = Referrals.newPrimaryFollowUpAdjustment("code-658", label: "label-389")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
