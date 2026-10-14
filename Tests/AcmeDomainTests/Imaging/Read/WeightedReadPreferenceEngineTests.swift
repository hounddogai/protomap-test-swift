@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedReadPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultWeightedReadPreferenceEngine()
        let item = Imaging.newWeightedReadPreference("code-253", title: "title-753")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
