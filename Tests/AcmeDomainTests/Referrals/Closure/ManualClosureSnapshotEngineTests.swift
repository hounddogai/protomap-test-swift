@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualClosureSnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultManualClosureSnapshotEngine(Kit.Flags.newRegistry())
        let item = Referrals.newManualClosureSnapshot("code-376", label: "label-151")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
