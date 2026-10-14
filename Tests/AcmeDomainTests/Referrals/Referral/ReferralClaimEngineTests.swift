@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultReferralClaimEngine(Kit.Flags.newRegistry())
        let item = Referrals.newReferralClaim("code-103", name: "name-122")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
