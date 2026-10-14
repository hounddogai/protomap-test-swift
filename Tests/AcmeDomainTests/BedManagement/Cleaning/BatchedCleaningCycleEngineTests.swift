@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedCleaningCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultBatchedCleaningCycleEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newBatchedCleaningCycle("code-335", title: "title-123")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
