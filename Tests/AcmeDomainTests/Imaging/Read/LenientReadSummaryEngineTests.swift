@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientReadSummaryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultLenientReadSummaryEngine()
        let item = Imaging.newLenientReadSummary("code-186", label: "label-614")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
