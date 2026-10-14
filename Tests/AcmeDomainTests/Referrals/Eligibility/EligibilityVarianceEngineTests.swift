@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultEligibilityVarianceEngine(Kit.Flags.newRegistry())
        let item = Referrals.newEligibilityVariance("code-330", label: "label-459")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
