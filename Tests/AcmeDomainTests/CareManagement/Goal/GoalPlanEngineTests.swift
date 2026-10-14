@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultGoalPlanEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newGoalPlan("code-84", name: "name-761")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
