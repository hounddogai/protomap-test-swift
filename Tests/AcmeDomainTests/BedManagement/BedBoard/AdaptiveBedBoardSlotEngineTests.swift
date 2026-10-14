@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveBedBoardSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultAdaptiveBedBoardSlotEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newAdaptiveBedBoardSlot("code-582", name: "name-127")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
