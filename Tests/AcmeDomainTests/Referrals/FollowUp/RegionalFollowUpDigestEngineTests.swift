@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalFollowUpDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultRegionalFollowUpDigestEngine()
        let item = Referrals.newRegionalFollowUpDigest("code-780", title: "title-644")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
