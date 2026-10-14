@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualCareProtocolSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultManualCareProtocolSlotEngine(Kit.Flags.newRegistry())
        let item = Imaging.newManualCareProtocolSlot("code-646", label: "label-866")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
