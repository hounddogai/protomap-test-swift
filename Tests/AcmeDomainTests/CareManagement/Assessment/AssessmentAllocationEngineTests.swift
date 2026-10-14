@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultAssessmentAllocationEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newAssessmentAllocation("code-869", name: "name-467")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
