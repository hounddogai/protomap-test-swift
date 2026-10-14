@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalFollowUpBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultSeasonalFollowUpBundleEngine()
        let item = Referrals.newSeasonalFollowUpBundle("code-648", name: "name-354")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
