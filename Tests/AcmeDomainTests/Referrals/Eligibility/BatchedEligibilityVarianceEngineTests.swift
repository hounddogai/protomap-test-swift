@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedEligibilityVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultBatchedEligibilityVarianceEngine(Kit.Flags.newRegistry())
        let item = Referrals.newBatchedEligibilityVariance("code-17", name: "name-985")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
