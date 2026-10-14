@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackClaimForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newFallbackClaimForecast("code-972", name: "name-840")
        let view = RevenueCycle.toFallbackClaimForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toFallbackClaimForecastViews([item, item]).count == 2)
    }
}
