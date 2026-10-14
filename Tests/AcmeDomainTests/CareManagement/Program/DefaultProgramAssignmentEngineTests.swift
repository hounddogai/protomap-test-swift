@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultProgramAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultDefaultProgramAssignmentEngine()
        let item = CareManagement.newDefaultProgramAssignment("code-458", title: "title-326")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
