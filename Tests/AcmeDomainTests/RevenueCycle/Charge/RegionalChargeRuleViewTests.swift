@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalChargeRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRegionalChargeRule("code-161", title: "title-473")
        let view = RevenueCycle.toRegionalChargeRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRegionalChargeRuleViews([item, item]).count == 2)
    }
}
