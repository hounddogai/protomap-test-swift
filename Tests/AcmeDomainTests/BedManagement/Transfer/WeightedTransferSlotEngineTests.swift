@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedTransferSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultWeightedTransferSlotEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newWeightedTransferSlot("code-414", name: "name-369")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
