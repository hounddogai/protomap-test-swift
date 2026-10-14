@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newChargeMetric("code-464", title: "title-919")
        let view = RevenueCycle.toChargeMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toChargeMetricViews([item, item]).count == 2)
    }
}
