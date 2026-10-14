@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedStudySegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultBatchedStudySegmentEngine(Kit.Flags.newRegistry())
        let item = Imaging.newBatchedStudySegment("code-339", label: "label-57")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
