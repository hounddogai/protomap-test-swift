@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultProgramPlanEngine()
        let item = CareManagement.newProgramPlan("code-595", title: "title-500")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
