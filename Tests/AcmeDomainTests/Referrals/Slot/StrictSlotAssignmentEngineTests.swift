@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictSlotAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultStrictSlotAssignmentEngine(Kit.Flags.newRegistry())
        let item = Referrals.newStrictSlotAssignment("code-650", name: "name-497")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
