@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultAssessmentBudgetEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newAssessmentBudget("code-565", label: "label-188")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
