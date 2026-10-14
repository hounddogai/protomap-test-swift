@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingEligibilityAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultPendingEligibilityAssignmentEngine(Kit.Flags.newRegistry())
        let item = Referrals.newPendingEligibilityAssignment("code-471", title: "title-33")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
