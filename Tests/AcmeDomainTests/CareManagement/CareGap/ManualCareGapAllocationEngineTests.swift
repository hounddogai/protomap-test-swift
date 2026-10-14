@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualCareGapAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultManualCareGapAllocationEngine()
        let item = CareManagement.newManualCareGapAllocation("code-931", title: "title-351")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
