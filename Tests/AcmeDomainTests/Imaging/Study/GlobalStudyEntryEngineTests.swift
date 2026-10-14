@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalStudyEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultGlobalStudyEntryEngine(Kit.Flags.newRegistry())
        let item = Imaging.newGlobalStudyEntry("code-853", label: "label-893")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
