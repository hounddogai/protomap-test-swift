@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalReferralClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultGlobalReferralClaimEngine()
        let item = Referrals.newGlobalReferralClaim("code-86", name: "name-591")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
