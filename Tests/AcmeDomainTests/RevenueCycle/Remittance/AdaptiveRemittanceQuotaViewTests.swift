@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveRemittanceQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newAdaptiveRemittanceQuota("code-890", label: "label-588")
        let view = RevenueCycle.toAdaptiveRemittanceQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toAdaptiveRemittanceQuotaViews([item, item]).count == 2)
    }
}
