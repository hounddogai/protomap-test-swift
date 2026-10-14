@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingFollowUpRuleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultRollingFollowUpRuleEngine()
        let item = Referrals.newRollingFollowUpRule("code-20", name: "name-805")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
