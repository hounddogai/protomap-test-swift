@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newChargeLedger("code-393", title: "title-778")
        let view = RevenueCycle.toChargeLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toChargeLedgerViews([item, item]).count == 2)
    }
}
