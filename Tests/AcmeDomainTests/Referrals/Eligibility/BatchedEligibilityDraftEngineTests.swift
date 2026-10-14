@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedEligibilityDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultBatchedEligibilityDraftEngine(Kit.Flags.newRegistry())
        let item = Referrals.newBatchedEligibilityDraft("code-949", title: "title-273")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
