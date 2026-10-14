@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningBatchEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultCleaningBatchEngine()
        let item = BedManagement.newCleaningBatch("code-359", label: "label-469")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
