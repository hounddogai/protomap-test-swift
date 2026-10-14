@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedReferralSnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultCappedReferralSnapshotEngine()
        let item = Referrals.newCappedReferralSnapshot("code-292", name: "name-745")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
