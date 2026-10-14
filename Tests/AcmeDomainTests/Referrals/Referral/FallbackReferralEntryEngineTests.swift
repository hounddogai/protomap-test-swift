@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackReferralEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultFallbackReferralEntryEngine()
        let item = Referrals.newFallbackReferralEntry("code-294", title: "title-658")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
