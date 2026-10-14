@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultTieredFollowUpBaselineEngine()
        let item = Referrals.newTieredFollowUpBaseline("code-752", title: "title-800")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
