@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingResultSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPendingResultSlotEngine()
        let item = Labs.newPendingResultSlot("code-723", name: "name-523")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
