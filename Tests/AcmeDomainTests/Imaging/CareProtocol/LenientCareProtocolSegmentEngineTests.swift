@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientCareProtocolSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultLenientCareProtocolSegmentEngine()
        let item = Imaging.newLenientCareProtocolSegment("code-231", title: "title-100")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
