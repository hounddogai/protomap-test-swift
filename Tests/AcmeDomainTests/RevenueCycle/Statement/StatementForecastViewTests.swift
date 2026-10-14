@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStatementForecast("code-518", title: "title-614")
        let view = RevenueCycle.toStatementForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStatementForecastViews([item, item]).count == 2)
    }
}
