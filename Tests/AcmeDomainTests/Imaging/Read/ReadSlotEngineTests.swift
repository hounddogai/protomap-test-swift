@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultReadSlotEngine()
        let item = Imaging.newReadSlot("code-190", label: "label-379")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
