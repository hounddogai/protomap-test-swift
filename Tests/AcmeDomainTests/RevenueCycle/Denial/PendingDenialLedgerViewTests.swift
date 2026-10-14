@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingDenialLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newPendingDenialLedger("code-755", title: "title-84")
        let view = RevenueCycle.toPendingDenialLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toPendingDenialLedgerViews([item, item]).count == 2)
    }
}
