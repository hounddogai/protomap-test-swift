@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyGoalCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultLegacyGoalCycleEngine()
        let item = CareManagement.newLegacyGoalCycle("code-738", title: "title-456")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
