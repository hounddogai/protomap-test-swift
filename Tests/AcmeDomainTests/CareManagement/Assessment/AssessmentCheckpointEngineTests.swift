@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultAssessmentCheckpointEngine()
        let item = CareManagement.newAssessmentCheckpoint("code-233", name: "name-503")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
