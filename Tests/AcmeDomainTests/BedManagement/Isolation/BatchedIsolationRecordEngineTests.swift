@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedIsolationRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultBatchedIsolationRecordEngine()
        let item = BedManagement.newBatchedIsolationRecord("code-421", label: "label-969")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
