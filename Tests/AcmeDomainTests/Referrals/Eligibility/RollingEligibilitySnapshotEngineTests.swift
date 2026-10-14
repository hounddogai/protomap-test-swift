@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingEligibilitySnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultRollingEligibilitySnapshotEngine()
        let item = Referrals.newRollingEligibilitySnapshot("code-801", name: "name-511")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
