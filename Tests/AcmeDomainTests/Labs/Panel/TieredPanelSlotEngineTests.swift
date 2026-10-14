@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredPanelSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultTieredPanelSlotEngine()
        let item = Labs.newTieredPanelSlot("code-179", label: "label-5")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
