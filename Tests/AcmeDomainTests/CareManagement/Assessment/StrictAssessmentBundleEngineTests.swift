@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictAssessmentBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultStrictAssessmentBundleEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newStrictAssessmentBundle("code-122", label: "label-246")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
