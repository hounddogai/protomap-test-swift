@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrioritySegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPrioritySegmentEngine()
        let item = Imaging.newPrioritySegment("code-539", name: "name-770")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
