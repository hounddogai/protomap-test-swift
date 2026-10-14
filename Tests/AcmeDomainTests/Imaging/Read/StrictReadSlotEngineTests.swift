@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictReadSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultStrictReadSlotEngine(Kit.Flags.newRegistry())
        let item = Imaging.newStrictReadSlot("code-82", title: "title-891")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
