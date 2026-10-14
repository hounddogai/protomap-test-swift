@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalDenialPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRegionalDenialPolicy("code-465", title: "title-46")
        let view = RevenueCycle.toRegionalDenialPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRegionalDenialPolicyViews([item, item]).count == 2)
    }
}
