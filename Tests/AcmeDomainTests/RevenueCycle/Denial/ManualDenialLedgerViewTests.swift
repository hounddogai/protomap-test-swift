@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualDenialLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newManualDenialLedger("code-602", name: "name-550")
        let view = RevenueCycle.toManualDenialLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toManualDenialLedgerViews([item, item]).count == 2)
    }
}
