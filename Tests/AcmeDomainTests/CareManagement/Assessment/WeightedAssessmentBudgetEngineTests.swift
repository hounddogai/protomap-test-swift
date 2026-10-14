@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedAssessmentBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultWeightedAssessmentBudgetEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newWeightedAssessmentBudget("code-888", title: "title-761")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
