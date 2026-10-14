@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalReferralCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultGlobalReferralCycleEngine(Kit.Flags.newRegistry())
        let item = Referrals.newGlobalReferralCycle("code-870", title: "title-611")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
