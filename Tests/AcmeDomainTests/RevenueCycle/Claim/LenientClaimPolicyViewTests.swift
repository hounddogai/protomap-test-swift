@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientClaimPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newLenientClaimPolicy("code-42", name: "name-282")
        let view = RevenueCycle.toLenientClaimPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toLenientClaimPolicyViews([item, item]).count == 2)
    }
}
