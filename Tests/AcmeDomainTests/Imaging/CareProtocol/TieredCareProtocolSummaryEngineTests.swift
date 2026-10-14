@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredCareProtocolSummaryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultTieredCareProtocolSummaryEngine()
        let item = Imaging.newTieredCareProtocolSummary("code-462", name: "name-175")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
