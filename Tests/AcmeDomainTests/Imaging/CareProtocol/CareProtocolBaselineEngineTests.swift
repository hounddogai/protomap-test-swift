@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultCareProtocolBaselineEngine()
        let item = Imaging.newCareProtocolBaseline("code-89", name: "name-921")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
