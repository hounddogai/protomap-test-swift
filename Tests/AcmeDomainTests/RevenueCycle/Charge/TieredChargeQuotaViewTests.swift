@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredChargeQuotaViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newTieredChargeQuota("code-407", label: "label-415")
        let view = RevenueCycle.toTieredChargeQuotaView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toTieredChargeQuotaViews([item, item]).count == 2)
    }
}
