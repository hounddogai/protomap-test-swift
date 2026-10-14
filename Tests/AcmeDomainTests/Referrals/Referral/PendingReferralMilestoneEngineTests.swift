@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingReferralMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultPendingReferralMilestoneEngine()
        let item = Referrals.newPendingReferralMilestone("code-27", name: "name-230")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
