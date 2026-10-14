@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkForecastEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultManualNetworkForecastEngine(Kit.Flags.newRegistry())
        let item = Referrals.newManualNetworkForecast("code-999", name: "name-111")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
