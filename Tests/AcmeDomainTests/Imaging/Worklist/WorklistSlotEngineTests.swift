@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultWorklistSlotEngine()
        let item = Imaging.newWorklistSlot("code-957", name: "name-998")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
