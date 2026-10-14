@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredReferralDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultTieredReferralDigestEngine()
        let item = Referrals.newTieredReferralDigest("code-653", title: "title-813")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
