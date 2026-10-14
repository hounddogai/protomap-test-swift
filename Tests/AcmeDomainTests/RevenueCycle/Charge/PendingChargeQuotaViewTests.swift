@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingChargeQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newPendingChargeQuota("code-80", title: "title-637")
        let view = RevenueCycle.toPendingChargeQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toPendingChargeQuotaViews([item, item]).count == 2)
    }
}
