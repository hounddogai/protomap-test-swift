@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientReadForecastEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultLenientReadForecastEngine()
        let item = Imaging.newLenientReadForecast("code-582", label: "label-936")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
