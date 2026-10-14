@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedTransferEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultBatchedTransferEntryEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newBatchedTransferEntry("code-118", name: "name-977")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
