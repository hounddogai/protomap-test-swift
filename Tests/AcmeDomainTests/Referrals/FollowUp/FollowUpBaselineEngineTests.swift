@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultFollowUpBaselineEngine()
        let item = Referrals.newFollowUpBaseline("code-68", title: "title-170")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
