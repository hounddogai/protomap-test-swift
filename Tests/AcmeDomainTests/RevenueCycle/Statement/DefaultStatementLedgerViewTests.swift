@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultStatementLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDefaultStatementLedger("code-262", title: "title-178")
        let view = RevenueCycle.toDefaultStatementLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDefaultStatementLedgerViews([item, item]).count == 2)
    }
}
