@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictDisclosureLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newStrictDisclosureLedger("code-132", name: "name-555")
        let view = Consent.toStrictDisclosureLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toStrictDisclosureLedgerViews([item, item]).count == 2)
    }
}
