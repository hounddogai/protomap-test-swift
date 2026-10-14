@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyReferralClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultLegacyReferralClaimEngine(Kit.Flags.newRegistry())
        let item = Referrals.newLegacyReferralClaim("code-281", name: "name-62")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
