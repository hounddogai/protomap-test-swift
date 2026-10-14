@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedSlotSnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultBatchedSlotSnapshotEngine(Kit.Flags.newRegistry())
        let item = Referrals.newBatchedSlotSnapshot("code-593", title: "title-16")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
