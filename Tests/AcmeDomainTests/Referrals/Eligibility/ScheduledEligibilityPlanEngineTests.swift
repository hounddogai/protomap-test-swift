@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledEligibilityPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultScheduledEligibilityPlanEngine(Kit.Flags.newRegistry())
        let item = Referrals.newScheduledEligibilityPlan("code-702", name: "name-673")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
