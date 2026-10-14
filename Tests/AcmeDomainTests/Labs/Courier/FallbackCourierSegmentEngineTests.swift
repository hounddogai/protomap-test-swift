@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackCourierSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultFallbackCourierSegmentEngine()
        let item = Labs.newFallbackCourierSegment("code-828", title: "title-294")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
