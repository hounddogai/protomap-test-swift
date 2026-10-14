@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newAuthorizationForecast("code-668", name: "name-405")
        let view = RevenueCycle.toAuthorizationForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toAuthorizationForecastViews([item, item]).count == 2)
    }
}
