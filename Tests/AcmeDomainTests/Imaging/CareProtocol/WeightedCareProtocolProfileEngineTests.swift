@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedCareProtocolProfileEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultWeightedCareProtocolProfileEngine()
        let item = Imaging.newWeightedCareProtocolProfile("code-454", title: "title-536")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
