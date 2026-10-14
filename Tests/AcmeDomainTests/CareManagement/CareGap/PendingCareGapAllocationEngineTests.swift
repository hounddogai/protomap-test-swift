@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingCareGapAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultPendingCareGapAllocationEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newPendingCareGapAllocation("code-160", title: "title-594")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
