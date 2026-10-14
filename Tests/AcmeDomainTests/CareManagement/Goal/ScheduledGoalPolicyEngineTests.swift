@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledGoalPolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultScheduledGoalPolicyEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newScheduledGoalPolicy("code-255", title: "title-533")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
