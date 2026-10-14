@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittancePolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRemittancePolicy("code-665", title: "title-642")
        let view = RevenueCycle.toRemittancePolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRemittancePolicyViews([item, item]).count == 2)
    }
}
