@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryEligibilityQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultPrimaryEligibilityQuotaEngine()
        let item = Referrals.newPrimaryEligibilityQuota("code-891", label: "label-124")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
