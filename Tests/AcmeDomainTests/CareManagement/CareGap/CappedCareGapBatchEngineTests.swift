@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedCareGapBatchEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultCappedCareGapBatchEngine()
        let item = CareManagement.newCappedCareGapBatch("code-357", name: "name-786")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
