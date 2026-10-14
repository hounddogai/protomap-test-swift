@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultCareGapAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultDefaultCareGapAssignmentEngine()
        let item = CareManagement.newDefaultCareGapAssignment("code-291", name: "name-77")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
