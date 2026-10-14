@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrioritySnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPrioritySnapshotEngine(Kit.Flags.newRegistry())
        let item = Imaging.newPrioritySnapshot("code-229", label: "label-826")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
