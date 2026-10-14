@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultReferralDigestEngine()
        let item = Referrals.newReferralDigest("code-99", label: "label-990")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
