@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrioritySlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPrioritySlotEngine()
        let item = Imaging.newPrioritySlot("code-422", title: "title-83")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
