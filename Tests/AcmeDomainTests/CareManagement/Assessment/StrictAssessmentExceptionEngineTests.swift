@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictAssessmentExceptionEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultStrictAssessmentExceptionEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newStrictAssessmentException("code-179", label: "label-872")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
