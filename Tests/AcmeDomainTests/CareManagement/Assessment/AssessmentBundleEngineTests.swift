@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultAssessmentBundleEngine()
        let item = CareManagement.newAssessmentBundle("code-669", label: "label-833")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
