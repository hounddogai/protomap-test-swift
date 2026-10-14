@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientEligibilityEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultLenientEligibilityEstimateEngine(Kit.Flags.newRegistry())
        let item = Referrals.newLenientEligibilityEstimate("code-846", name: "name-264")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
