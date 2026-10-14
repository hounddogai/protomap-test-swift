@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalFollowUpReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultRegionalFollowUpReservationEngine()
        let item = Referrals.newRegionalFollowUpReservation("code-22", name: "name-758")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
