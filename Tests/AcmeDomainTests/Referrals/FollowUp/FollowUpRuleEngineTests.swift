@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpRuleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultFollowUpRuleEngine()
        let item = Referrals.newFollowUpRule("code-881", title: "title-701")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
