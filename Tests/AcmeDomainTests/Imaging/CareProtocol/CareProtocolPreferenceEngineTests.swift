@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultCareProtocolPreferenceEngine()
        let item = Imaging.newCareProtocolPreference("code-27", name: "name-976")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
