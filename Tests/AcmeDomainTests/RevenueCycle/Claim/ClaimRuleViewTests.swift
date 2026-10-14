@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimRule("code-32", title: "title-958")
        let view = RevenueCycle.toClaimRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimRuleViews([item, item]).count == 2)
    }
}
