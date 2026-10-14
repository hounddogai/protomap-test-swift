@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyFollowUpCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultLegacyFollowUpCheckpointEngine()
        let item = Referrals.newLegacyFollowUpCheckpoint("code-584", name: "name-673")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
