@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelSlotEngine()
        let item = Labs.newPanelSlot("code-720", label: "label-278")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
