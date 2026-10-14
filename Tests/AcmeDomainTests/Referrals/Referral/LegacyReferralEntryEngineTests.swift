@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyReferralEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultLegacyReferralEntryEngine(Kit.Flags.newRegistry())
        let item = Referrals.newLegacyReferralEntry("code-300", title: "title-200")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
