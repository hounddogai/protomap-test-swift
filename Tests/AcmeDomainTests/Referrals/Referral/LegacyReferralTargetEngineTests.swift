@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyReferralTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultLegacyReferralTargetEngine()
        let item = Referrals.newLegacyReferralTarget("code-973", title: "title-487")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
