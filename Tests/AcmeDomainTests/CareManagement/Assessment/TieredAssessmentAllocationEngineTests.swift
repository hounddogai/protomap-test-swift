@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredAssessmentAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultTieredAssessmentAllocationEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newTieredAssessmentAllocation("code-131", label: "label-865")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
