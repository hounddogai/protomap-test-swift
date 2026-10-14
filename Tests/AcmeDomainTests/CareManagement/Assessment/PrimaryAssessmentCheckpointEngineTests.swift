@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryAssessmentCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultPrimaryAssessmentCheckpointEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newPrimaryAssessmentCheckpoint("code-282", name: "name-215")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
