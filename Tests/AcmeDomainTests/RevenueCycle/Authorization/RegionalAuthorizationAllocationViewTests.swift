@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalAuthorizationAllocationViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRegionalAuthorizationAllocation("code-943", label: "label-95")
        let view = RevenueCycle.toRegionalAuthorizationAllocationView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRegionalAuthorizationAllocationViews([item, item]).count == 2)
    }
}
