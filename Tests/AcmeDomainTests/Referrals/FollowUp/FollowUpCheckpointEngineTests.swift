@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultFollowUpCheckpointEngine(Kit.Flags.newRegistry())
        let item = Referrals.newFollowUpCheckpoint("code-599", title: "title-698")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
