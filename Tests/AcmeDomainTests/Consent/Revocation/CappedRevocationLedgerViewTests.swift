@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedRevocationLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newCappedRevocationLedger("code-691", name: "name-707")
        let view = Consent.toCappedRevocationLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toCappedRevocationLedgerViews([item, item]).count == 2)
    }
}
