@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultWeightedFollowUpAssignmentEngine(Kit.Flags.newRegistry())
        let item = Referrals.newWeightedFollowUpAssignment("code-43", label: "label-943")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
