@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackEligibilityPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultFallbackEligibilityPlanEngine()
        let item = Referrals.newFallbackEligibilityPlan("code-207", title: "title-13")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
