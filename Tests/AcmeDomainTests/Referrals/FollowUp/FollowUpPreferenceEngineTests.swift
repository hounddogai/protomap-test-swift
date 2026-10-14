@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultFollowUpPreferenceEngine()
        let item = Referrals.newFollowUpPreference("code-265", name: "name-485")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
