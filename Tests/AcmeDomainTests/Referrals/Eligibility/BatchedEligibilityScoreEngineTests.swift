@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedEligibilityScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultBatchedEligibilityScoreEngine(Kit.Flags.newRegistry())
        let item = Referrals.newBatchedEligibilityScore("code-401", title: "title-206")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
