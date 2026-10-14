@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpAdjustmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultFollowUpAdjustmentEngine()
        let item = Referrals.newFollowUpAdjustment("code-908", name: "name-15")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
