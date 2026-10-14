@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalReadSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultGlobalReadSlotEngine(Kit.Flags.newRegistry())
        let item = Imaging.newGlobalReadSlot("code-189", name: "name-254")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
