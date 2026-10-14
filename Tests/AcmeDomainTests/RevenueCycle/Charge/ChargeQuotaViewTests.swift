@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newChargeQuota("code-771", title: "title-55")
        let view = RevenueCycle.toChargeQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toChargeQuotaViews([item, item]).count == 2)
    }
}
