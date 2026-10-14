@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingEligibilityVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultRollingEligibilityVarianceEngine(Kit.Flags.newRegistry())
        let item = Referrals.newRollingEligibilityVariance("code-884", title: "title-709")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
