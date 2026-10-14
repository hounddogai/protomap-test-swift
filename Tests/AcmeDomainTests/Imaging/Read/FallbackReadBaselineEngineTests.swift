@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackReadBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultFallbackReadBaselineEngine()
        let item = Imaging.newFallbackReadBaseline("code-97", title: "title-654")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
