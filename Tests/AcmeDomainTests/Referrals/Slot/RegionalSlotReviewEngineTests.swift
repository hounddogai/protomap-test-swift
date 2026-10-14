@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalSlotReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultRegionalSlotReviewEngine()
        let item = Referrals.newRegionalSlotReview("code-921", title: "title-782")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
