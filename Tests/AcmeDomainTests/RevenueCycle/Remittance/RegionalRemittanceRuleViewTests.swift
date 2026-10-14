@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalRemittanceRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRegionalRemittanceRule("code-942", label: "label-989")
        let view = RevenueCycle.toRegionalRemittanceRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRegionalRemittanceRuleViews([item, item]).count == 2)
    }
}
