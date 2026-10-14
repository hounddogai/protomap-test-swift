@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedCleaningSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultCappedCleaningSlotEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newCappedCleaningSlot("code-201", label: "label-812")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
