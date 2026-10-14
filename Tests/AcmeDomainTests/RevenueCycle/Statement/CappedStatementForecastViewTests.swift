@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedStatementForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newCappedStatementForecast("code-600", name: "name-363")
        let view = RevenueCycle.toCappedStatementForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toCappedStatementForecastViews([item, item]).count == 2)
    }
}
