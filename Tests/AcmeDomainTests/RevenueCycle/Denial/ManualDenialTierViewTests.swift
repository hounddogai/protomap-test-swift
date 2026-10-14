@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualDenialTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newManualDenialTier("code-293", label: "label-759")
        let view = RevenueCycle.toManualDenialTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toManualDenialTierViews([item, item]).count == 2)
    }
}
