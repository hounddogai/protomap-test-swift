@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolSummaryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultCareProtocolSummaryEngine()
        let item = Imaging.newCareProtocolSummary("code-652", label: "label-362")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
