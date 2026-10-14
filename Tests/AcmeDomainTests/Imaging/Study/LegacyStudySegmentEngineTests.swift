@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyStudySegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultLegacyStudySegmentEngine()
        let item = Imaging.newLegacyStudySegment("code-359", label: "label-12")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
