@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualClosureReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultManualClosureReviewEngine(Kit.Flags.newRegistry())
        let item = Referrals.newManualClosureReview("code-595", name: "name-880")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
