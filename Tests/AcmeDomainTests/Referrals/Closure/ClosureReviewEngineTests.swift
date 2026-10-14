@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultClosureReviewEngine()
        let item = Referrals.newClosureReview("code-943", name: "name-445")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
