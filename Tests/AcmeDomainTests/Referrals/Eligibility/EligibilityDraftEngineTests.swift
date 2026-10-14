@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultEligibilityDraftEngine(Kit.Flags.newRegistry())
        let item = Referrals.newEligibilityDraft("code-524", title: "title-277")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
