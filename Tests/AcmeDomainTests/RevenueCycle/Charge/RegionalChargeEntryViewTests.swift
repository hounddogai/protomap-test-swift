@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalChargeEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRegionalChargeEntry("code-216", label: "label-822")
        let view = RevenueCycle.toRegionalChargeEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRegionalChargeEntryViews([item, item]).count == 2)
    }
}
