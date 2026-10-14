@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultProgramAssignmentEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newProgramAssignment("code-526", title: "title-514")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
