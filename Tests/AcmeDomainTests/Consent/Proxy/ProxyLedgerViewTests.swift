@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyLedger("code-237", label: "label-883")
        let view = Consent.toProxyLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyLedgerViews([item, item]).count == 2)
    }
}
