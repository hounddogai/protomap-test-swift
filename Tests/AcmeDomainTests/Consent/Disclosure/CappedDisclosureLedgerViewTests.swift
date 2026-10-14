@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedDisclosureLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newCappedDisclosureLedger("code-765", name: "name-50")
        let view = Consent.toCappedDisclosureLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toCappedDisclosureLedgerViews([item, item]).count == 2)
    }
}
