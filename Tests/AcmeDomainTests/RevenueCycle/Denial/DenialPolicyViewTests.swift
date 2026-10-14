@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDenialPolicy("code-39", name: "name-25")
        let view = RevenueCycle.toDenialPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDenialPolicyViews([item, item]).count == 2)
    }
}
