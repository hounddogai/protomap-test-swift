@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultEligibilityAssignmentEngine(Kit.Flags.newRegistry())
        let item = Referrals.newEligibilityAssignment("code-124", name: "name-90")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
