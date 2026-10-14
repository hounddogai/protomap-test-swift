@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledAuthorizationMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newScheduledAuthorizationMetric("code-193", label: "label-465")
        let view = RevenueCycle.toScheduledAuthorizationMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toScheduledAuthorizationMetricViews([item, item]).count == 2)
    }
}
