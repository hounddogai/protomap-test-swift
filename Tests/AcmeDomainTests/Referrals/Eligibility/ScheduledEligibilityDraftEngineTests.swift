@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledEligibilityDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultScheduledEligibilityDraftEngine()
        let item = Referrals.newScheduledEligibilityDraft("code-412", name: "name-403")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
