@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalAccessionSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultSeasonalAccessionSegmentEngine(Kit.Flags.newRegistry())
        let item = Labs.newSeasonalAccessionSegment("code-52", label: "label-905")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
