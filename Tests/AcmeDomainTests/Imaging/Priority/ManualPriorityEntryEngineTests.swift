@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualPriorityEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultManualPriorityEntryEngine(Kit.Flags.newRegistry())
        let item = Imaging.newManualPriorityEntry("code-788", label: "label-234")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
