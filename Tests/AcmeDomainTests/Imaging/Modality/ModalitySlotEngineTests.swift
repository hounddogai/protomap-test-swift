@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalitySlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultModalitySlotEngine(Kit.Flags.newRegistry())
        let item = Imaging.newModalitySlot("code-583", label: "label-518")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
