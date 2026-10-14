@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimMetric("code-413", name: "name-454")
        let view = RevenueCycle.toClaimMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimMetricViews([item, item]).count == 2)
    }
}
