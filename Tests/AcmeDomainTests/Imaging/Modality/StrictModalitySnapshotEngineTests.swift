@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictModalitySnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultStrictModalitySnapshotEngine(Kit.Flags.newRegistry())
        let item = Imaging.newStrictModalitySnapshot("code-359", label: "label-371")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
