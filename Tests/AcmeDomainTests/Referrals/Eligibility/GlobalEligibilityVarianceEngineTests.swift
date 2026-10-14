@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalEligibilityVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultGlobalEligibilityVarianceEngine(Kit.Flags.newRegistry())
        let item = Referrals.newGlobalEligibilityVariance("code-440", title: "title-839")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
