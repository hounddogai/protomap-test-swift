@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalEligibilityQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultSeasonalEligibilityQuotaEngine()
        let item = Referrals.newSeasonalEligibilityQuota("code-316", name: "name-77")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
