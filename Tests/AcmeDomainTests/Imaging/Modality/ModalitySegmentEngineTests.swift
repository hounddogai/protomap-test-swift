@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalitySegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultModalitySegmentEngine(Kit.Flags.newRegistry())
        let item = Imaging.newModalitySegment("code-827", title: "title-235")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
