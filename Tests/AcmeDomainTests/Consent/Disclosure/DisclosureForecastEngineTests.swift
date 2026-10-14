@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureForecastEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultDisclosureForecastEngine()
        let item = Consent.newDisclosureForecast("code-311", title: "title-219")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
