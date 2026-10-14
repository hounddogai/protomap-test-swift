@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedAssessmentBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultCappedAssessmentBaselineEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newCappedAssessmentBaseline("code-497", label: "label-123")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
