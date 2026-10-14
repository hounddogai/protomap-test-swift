@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRemittanceMetric("code-500", title: "title-791")
        let view = RevenueCycle.toRemittanceMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRemittanceMetricViews([item, item]).count == 2)
    }
}
