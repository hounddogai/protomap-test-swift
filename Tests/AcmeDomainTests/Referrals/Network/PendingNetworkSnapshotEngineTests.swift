@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingNetworkSnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultPendingNetworkSnapshotEngine()
        let item = Referrals.newPendingNetworkSnapshot("code-220", title: "title-599")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
