@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpBatchEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultTieredFollowUpBatchEngine(Kit.Flags.newRegistry())
        let item = Referrals.newTieredFollowUpBatch("code-89", title: "title-976")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
