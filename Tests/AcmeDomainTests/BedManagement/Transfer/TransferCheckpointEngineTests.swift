@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultTransferCheckpointEngine()
        let item = BedManagement.newTransferCheckpoint("code-274", title: "title-261")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
