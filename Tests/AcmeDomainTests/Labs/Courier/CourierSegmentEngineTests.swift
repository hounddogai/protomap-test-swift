@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierSegmentEngine(Kit.Flags.newRegistry())
        let item = Labs.newCourierSegment("code-519", title: "title-262")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
