@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newChargeRule("code-104", title: "title-769")
        let view = RevenueCycle.toChargeRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toChargeRuleViews([item, item]).count == 2)
    }
}
