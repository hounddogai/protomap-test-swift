@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictReferralPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultStrictReferralPreferenceEngine()
        let item = Referrals.newStrictReferralPreference("code-724", name: "name-878")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
