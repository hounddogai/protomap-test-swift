@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultRecallForecastEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultDefaultRecallForecastEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newDefaultRecallForecast("code-766", title: "title-636")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
