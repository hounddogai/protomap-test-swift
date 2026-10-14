@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveAssessmentAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultAdaptiveAssessmentAssignmentEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newAdaptiveAssessmentAssignment("code-586", title: "title-500")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
