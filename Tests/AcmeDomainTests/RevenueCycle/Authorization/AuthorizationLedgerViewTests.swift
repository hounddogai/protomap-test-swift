@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newAuthorizationLedger("code-866", label: "label-923")
        let view = RevenueCycle.toAuthorizationLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toAuthorizationLedgerViews([item, item]).count == 2)
    }
}
