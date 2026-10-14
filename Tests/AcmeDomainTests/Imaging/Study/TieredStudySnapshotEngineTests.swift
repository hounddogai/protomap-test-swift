@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredStudySnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultTieredStudySnapshotEngine(Kit.Flags.newRegistry())
        let item = Imaging.newTieredStudySnapshot("code-114", title: "title-985")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
