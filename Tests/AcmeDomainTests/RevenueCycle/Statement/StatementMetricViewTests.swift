@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStatementMetric("code-19", name: "name-405")
        let view = RevenueCycle.toStatementMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStatementMetricViews([item, item]).count == 2)
    }
}
